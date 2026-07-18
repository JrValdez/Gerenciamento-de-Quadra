using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
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

    public AuthController(
        UserManager<ApplicationUser> userManager,
        SignInManager<ApplicationUser> signInManager,
        TokenService tokenService,
        AppDbContext db)
    {
        _userManager = userManager;
        _signInManager = signInManager;
        _tokenService = tokenService;
        _db = db;
    }

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

    /// <summary>Registro de novos usuários internos (Atendente/Cliente). Somente Admin.</summary>
    [HttpPost("register")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<UsuarioDto>> Register(RegisterRequest req)
    {
        if (!Roles.All.Contains(req.Papel))
            return BadRequest(new { erro = "Papel inválido." });

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

    /// <summary>Lista todos os usuários do sistema. Somente Admin.</summary>
    [HttpGet("usuarios")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<IEnumerable<UsuarioDto>>> Usuarios()
    {
        var users = _userManager.Users.OrderBy(u => u.NomeCompleto).ToList();
        var lista = new List<UsuarioDto>();
        foreach (var u in users)
        {
            var papeis = await _userManager.GetRolesAsync(u);
            lista.Add(new UsuarioDto(u.Id, u.NomeCompleto, u.Email!, papeis, u.Ativo));
        }
        return Ok(lista);
    }

    /// <summary>Ativa/inativa um usuário. Somente Admin.</summary>
    [HttpPatch("usuarios/{id:guid}/ativo")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<ActionResult<UsuarioDto>> DefinirAtivo(Guid id, AtivoRequest req)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        var eu = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (eu == id.ToString() && !req.Ativo)
            return BadRequest(new { erro = "Você não pode inativar a si mesmo." });

        user.Ativo = req.Ativo;
        await _userManager.UpdateAsync(user);
        var papeis = await _userManager.GetRolesAsync(user);
        return Ok(new UsuarioDto(user.Id, user.NomeCompleto, user.Email!, papeis, user.Ativo));
    }

    /// <summary>Exclui um usuário. Somente Admin. Não é possível excluir a si mesmo.</summary>
    [HttpDelete("usuarios/{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> ExcluirUsuario(Guid id)
    {
        var eu = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (eu == id.ToString())
            return BadRequest(new { erro = "Você não pode excluir a si mesmo." });

        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();

        // Remove vínculos na competição (FK restrita); competidores que ficarem
        // sem integrantes (ex.: o individual do próprio aluno) também são removidos.
        var membros = await _db.CompetidorMembros.Where(m => m.AlunoId == id).ToListAsync();
        if (membros.Count > 0)
        {
            var competidorIds = membros.Select(m => m.CompetidorId).Distinct().ToList();
            _db.CompetidorMembros.RemoveRange(membros);
            await _db.SaveChangesAsync();

            var vazios = await _db.Competidores
                .Where(c => competidorIds.Contains(c.Id) && !c.Membros.Any())
                .ToListAsync();
            if (vazios.Count > 0)
            {
                _db.Competidores.RemoveRange(vazios);
                await _db.SaveChangesAsync();
            }
        }

        var result = await _userManager.DeleteAsync(user);
        if (!result.Succeeded)
            return BadRequest(new { erro = string.Join("; ", result.Errors.Select(e => e.Description)) });

        return NoContent();
    }
}
