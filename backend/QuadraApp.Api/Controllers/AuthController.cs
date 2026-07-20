using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;
using QuadraApp.Api.Services;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly SignInManager<ApplicationUser> _signInManager;
    private readonly TokenService _tokenService;
    private readonly AppDbContext _db;
    private readonly IEmailSender _emailSender;
    private readonly IConfiguration _config;
    private readonly ILogger<AuthController> _logger;
    private readonly IMemoryCache _cache;

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        TokenService tokenService,
        AppDbContext db,
        IEmailSender emailSender,
        IConfiguration config,
        ILogger<AuthController> logger,
        IMemoryCache cache)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _tokenService = tokenService;
        _db = db;
        _emailSender = emailSender;
        _config = config;
        _logger = logger;
        _cache = cache;
    }

    /// <summary>
    /// Remove o snapshot de revogação em cache do usuário, para que a próxima requisição
    /// releia o estado atual do banco (revogação imediata após inativar/redefinir/excluir).
    /// </summary>
    private void InvalidarSnapshot(Guid userId) =>
        _cache.Remove(AuthUserSnapshot.Chave(userId.ToString()));

    /// <summary>True se o usuário autenticado é Admin.</summary>
    private bool SouAdmin() => User.IsInRole(Roles.Admin);

    /// <summary>Um Atendente não pode alterar contas que sejam Administrador.</summary>
    private async Task<bool> AtendenteMexendoEmAdmin(ApplicationUser alvo) =>
        !SouAdmin() && await _userManager.IsInRoleAsync(alvo, Roles.Admin);

    [HttpPost("login")]
    public async Task<ActionResult<AuthResponse>> Login(LoginRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null || !user.Ativo)
            return Unauthorized(new { erro = "Credenciais inválidas." });

        var ok = await _signInManager.CheckPasswordSignInAsync(user, req.Senha, lockoutOnFailure: false);
        if (!ok.Succeeded)
            return Unauthorized(new { erro = "Credenciais inválidas." });

        var papeis = await _userManager.GetRolesAsync(user);
        var (token, expiraEm) = _tokenService.GerarToken(user, papeis);

        return Ok(new AuthResponse(token, expiraEm,
            new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo)));
    }

    /// <summary>Envia um link de redefinição de senha por e-mail. Público.</summary>
    [HttpPost("forgot-password")]
    [AllowAnonymous]
    [EnableRateLimiting("auth-sensivel")]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);

        // Só envia se o usuário existe e está ativo — mas a resposta é sempre a mesma,
        // para não revelar quais e-mails estão cadastrados.
        if (user is not null && user.Ativo)
        {
            var token = await _userManager.GeneratePasswordResetTokenAsync(user);
            var baseUrl = (_config["App:AppBaseUrl"] ?? string.Empty).TrimEnd('/');
            var link = $"{baseUrl}/#/redefinir-senha" +
                       $"?email={Uri.EscapeDataString(user.Email!)}" +
                       $"&token={Uri.EscapeDataString(token)}";

            var html = $@"
                <p>Olá,</p>
                <p>Recebemos um pedido para redefinir a sua senha no <b>Gerenciamento de Quadra</b>.</p>
                <p><a href=""{link}"">Clique aqui para criar uma nova senha</a>.</p>
                <p>Se você não fez esse pedido, ignore este e-mail — sua senha continua a mesma.
                O link expira em breve por segurança.</p>";

            // Uma falha de envio não pode virar erro para o cliente (a resposta é
            // sempre genérica) nem derrubar a requisição — apenas registramos.
            try
            {
                await _emailSender.EnviarAsync(user.Email!, "Redefinição de senha", html);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Falha ao enviar e-mail de redefinição para {Email}.", user.Email);
            }
        }

        return Ok(new { mensagem = "Se o e-mail estiver cadastrado, enviamos um link de redefinição." });
    }

    /// <summary>Redefine a senha usando o token recebido por e-mail. Público.</summary>
    [HttpPost("reset-password")]
    [AllowAnonymous]
    [EnableRateLimiting("auth-sensivel")]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest req)
    {
        var user = await _userManager.FindByEmailAsync(req.Email);
        if (user is null)
            return BadRequest(new { erro = "Não foi possível redefinir a senha." });

        var resultado = await _userManager.ResetPasswordAsync(user, req.Token, req.NovaSenha);
        if (!resultado.Succeeded)
            return BadRequest(new { erro = "Link inválido ou expirado. Solicite um novo." });

        // A troca de senha rotaciona o security stamp: derruba os tokens antigos na hora.
        InvalidarSnapshot(user.Id);
        return Ok(new { mensagem = "Senha redefinida com sucesso. Já pode entrar com a nova senha." });
    }

    /// <summary>Registro de novos usuários. Admin/Atendente.</summary>
    [HttpPost("register")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<UsuarioDto>> Register(RegisterRequest req)
    {
        if (!Roles.All.Contains(req.Papel))
            return BadRequest(new { erro = "Papel inválido." });

        if (!SouAdmin() && req.Papel == Roles.Admin)
            return StatusCode(StatusCodes.Status403Forbidden,
                new { erro = "Atendente não pode criar administradores." });

        if (await _userManager.FindByEmailAsync(req.Email) is not null)
            return Conflict(new { erro = "E-mail já cadastrado." });

        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email,
            EmailConfirmed = true,
            NomeCompleto = req.NomeCompleto,
        };

        var result = await _userManager.CreateAsync(user, req.Senha);
        if (!result.Succeeded)
            return BadRequest(new { erro = string.Join("; ", result.Errors.Select(e => e.Description)) });

        await _userManager.AddToRoleAsync(user, req.Papel);
        var papeis = await _userManager.GetRolesAsync(user);

        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo));
    }

    [HttpGet("me")]
    [Authorize]
    public async Task<ActionResult<UsuarioDto>> Me()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (id is null) return Unauthorized();

        var user = await _userManager.FindByIdAsync(id);
        if (user is null) return Unauthorized();

        var papeis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo));
    }

    /// <summary>Lista todos os usuários do sistema. Admin/Atendente.</summary>
    [HttpGet("usuarios")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<IEnumerable<UsuarioDto>>> Usuarios(CancellationToken ct)
    {
        var users = await _userManager.Users.OrderBy(u => u.NomeCompleto).ToListAsync(ct);

        // Papéis de todos os usuários em UMA consulta (evita o N+1 de um GetRolesAsync
        // por usuário): junta UserRoles com Roles e agrupa por usuário.
        var papeisPorUsuario = await (
            from ur in _db.UserRoles
            join r in _db.Roles on ur.RoleId equals r.Id
            select new { ur.UserId, r.Name })
            .ToListAsync(ct);
        var mapa = papeisPorUsuario
            .GroupBy(x => x.UserId)
            .ToDictionary(g => g.Key, g => g.Select(x => x.Name!).ToList());

        var lista = users.Select(u => new UsuarioDto(
            u.Id, u.NomeCompleto, u.Email!,
            mapa.TryGetValue(u.Id, out var papeis) ? papeis : new List<string>(),
            u.Ativo, u.PhoneNumber));
        return Ok(lista);
    }

    /// <summary>Edita nome, e-mail e telefone de um usuário. Admin/Atendente.</summary>
    [HttpPut("usuarios/{id:guid}")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<UsuarioDto>> EditarUsuario(Guid id, EditarUsuarioRequest req)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        if (await AtendenteMexendoEmAdmin(user))
            return StatusCode(StatusCodes.Status403Forbidden,
                new { erro = "Atendente não pode alterar administradores." });

        var outro = await _userManager.FindByEmailAsync(req.Email);
        if (outro is not null && outro.Id != user.Id)
            return Conflict(new { erro = "E-mail já cadastrado." });

        user.NomeCompleto = req.NomeCompleto;
        user.PhoneNumber = string.IsNullOrWhiteSpace(req.Telefone) ? null : req.Telefone.Trim();
        if (!string.Equals(user.Email, req.Email, StringComparison.OrdinalIgnoreCase))
        {
            user.Email = req.Email;
            user.UserName = req.Email;
        }

        var result = await _userManager.UpdateAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { erro = string.Join("; ", result.Errors.Select(e => e.Description)) });

        var papeis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo, user.PhoneNumber));
    }

    /// <summary>Ativa/inativa um usuário. Admin/Atendente.</summary>
    [HttpPatch("usuarios/{id:guid}/ativo")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<UsuarioDto>> DefinirAtivo(Guid id, AtivoRequest req)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        if (await AtendenteMexendoEmAdmin(user))
            return StatusCode(StatusCodes.Status403Forbidden,
                new { erro = "Atendente não pode alterar administradores." });

        var eu = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (eu == id.ToString() && !req.Ativo)
            return BadRequest(new { erro = "Você não pode inativar a si mesmo." });

        user.Ativo = req.Ativo;
        await _userManager.UpdateAsync(user);
        // Inativar deve derrubar a sessão imediatamente (não esperar o cache expirar).
        InvalidarSnapshot(user.Id);
        var papeis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo, user.PhoneNumber));
    }

    /// <summary>Altera o papel (classificação) de um usuário. Admin/Atendente.</summary>
    [HttpPut("usuarios/{id:guid}/papel")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<UsuarioDto>> DefinirPapel(Guid id, PapelRequest req)
    {
        if (!Roles.All.Contains(req.Papel))
            return BadRequest(new { erro = "Papel inválido." });

        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        var eu = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (eu == id.ToString())
            return BadRequest(new { erro = "Você não pode alterar o próprio papel." });

        if (!SouAdmin() && (await _userManager.IsInRoleAsync(user, Roles.Admin) || req.Papel == Roles.Admin))
            return StatusCode(StatusCodes.Status403Forbidden,
                new { erro = "Atendente não pode alterar administradores." });

        var atuais = await _userManager.GetRolesAsync(user);
        if (atuais.Count > 0)
            await _userManager.RemoveFromRolesAsync(user, atuais);
        await _userManager.AddToRoleAsync(user, req.Papel);

        var papeis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo, user.PhoneNumber));
    }

    /// <summary>Exclui um usuário. Admin/Atendente. Não é possível excluir a si mesmo.</summary>
    [HttpDelete("usuarios/{id:guid}")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<IActionResult> ExcluirUsuario(Guid id, CancellationToken ct)
    {
        var eu = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (eu == id.ToString())
            return BadRequest(new { erro = "Você não pode excluir a si mesmo." });

        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        if (await AtendenteMexendoEmAdmin(user))
            return StatusCode(StatusCodes.Status403Forbidden,
                new { erro = "Atendente não pode alterar administradores." });

        // Remove vínculos na competição (FK restrita); competidores que ficarem
        // sem integrantes (ex.: o individual do próprio aluno) também são removidos.
        var membros = await _db.CompetidorMembros.Where(m => m.AlunoId == id).ToListAsync(ct);
        if (membros.Count > 0)
        {
            var competidorIds = membros.Select(m => m.CompetidorId).Distinct().ToList();
            _db.CompetidorMembros.RemoveRange(membros);
            await _db.SaveChangesAsync(ct);

            var vazios = await _db.Competidores
                .Where(c => competidorIds.Contains(c.Id) && !c.Membros.Any())
                .ToListAsync(ct);
            if (vazios.Count > 0)
            {
                _db.Competidores.RemoveRange(vazios);
                await _db.SaveChangesAsync(ct);
            }
        }

        var result = await _userManager.DeleteAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { erro = string.Join("; ", result.Errors.Select(e => e.Description)) });

        InvalidarSnapshot(user.Id);
        return NoContent();
    }
}
