using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;
using QuadraApp.Api.Services;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgendamentosController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly AgendamentoService _svc;
    private readonly TimeZoneInfo _fuso;

    public AgendamentosController(
        AppDbContext db, UserManager<ApplicationUser> userManager,
        AgendamentoService svc, TimeZoneInfo fuso)
    {
        _db = db;
        _userManager = userManager;
        _svc = svc;
        _fuso = fuso;
    }

    /// <summary>
    /// Garante que quem reservou uma quadra pelo calendário exista como usuário
    /// da categoria Cliente. É best-effort: se a criação falhar, a reserva continua
    /// válida. Não altera contas já existentes (ex.: Aluno/Atendente que reservam).
    /// </summary>
    private async Task EnsureClienteAsync(string? nome, string? email)
    {
        if (string.IsNullOrWhiteSpace(email) || !email.Contains('@')) return;

        var emailNormalizado = email.Trim();
        if (await _userManager.FindByEmailAsync(emailNormalizado) is not null) return;

        var user = new ApplicationUser
        {
            UserName = emailNormalizado,
            Email = emailNormalizado,
            EmailConfirmed = true,
            NomeCompleto = string.IsNullOrWhiteSpace(nome) ? emailNormalizado : nome.Trim(),
        };

        // Criado sem senha: aparece na tela de Usuários como Cliente; um Admin
        // pode definir uma senha depois caso o cliente precise de acesso.
        var result = await _userManager.CreateAsync(user);
        if (result.Succeeded)
            await _userManager.AddToRoleAsync(user, Roles.Cliente);
    }

    private static AgendamentoDto Map(Agendamento a) =>
        new(a.Id, a.QuadraId, a.Quadra?.Nome ?? "", a.Inicio, a.Fim,
            a.NomeCliente, a.TelefoneCliente, a.EmailCliente,
            a.Status, a.ValorTotal, a.Observacoes, a.CriadoEm,
            a.ValorDesconto, a.CupomCodigo);

    private Guid? UsuarioAtual()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(id, out var g) ? g : null;
    }

    // ----- Público: agendar sem login -----
    [HttpPost("publico")]
    [AllowAnonymous]
    public async Task<ActionResult<AgendamentoDto>> AgendarPublico(AgendamentoPublicoRequest req)
    {
        if (req.Fim <= req.Inicio)
            return BadRequest(new { erro = "Horário final deve ser maior que o inicial." });
        if (req.Inicio < DateTime.UtcNow.AddMinutes(-1))
            return BadRequest(new { erro = "Não é possível agendar no passado." });

        var quadra = await _db.Quadras.FindAsync(req.QuadraId);
        if (quadra is null || !quadra.Ativa)
            return BadRequest(new { erro = "Quadra indisponível." });

        if (await _svc.ExisteConflitoAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        if (await _svc.ExisteBloqueioAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Quadra bloqueada nesse horário." });

        var bruto = AgendamentoService.CalcularValor(quadra.PrecoHora, req.Inicio, req.Fim);
        var (cupom, desconto, erroCupom) = await _svc.ResolverCupomAsync(req.CupomCodigo, bruto);
        if (erroCupom is not null) return BadRequest(new { erro = erroCupom });

        var ag = new Agendamento
        {
            QuadraId = req.QuadraId,
            Inicio = req.Inicio,
            Fim = req.Fim,
            NomeCliente = req.NomeCliente,
            TelefoneCliente = req.TelefoneCliente,
            EmailCliente = req.EmailCliente,
            Observacoes = req.Observacoes,
            Status = StatusAgendamento.Pendente,
            ValorTotal = bruto - desconto,
            ValorDesconto = desconto,
            CupomId = cupom?.Id,
            CupomCodigo = cupom?.Codigo,
        };
        _db.Agendamentos.Add(ag);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (PgErros.EhOverlap(ex))
        {
            // Rede de segurança da constraint de exclusão: duas reservas concorrentes
            // do mesmo horário — só uma passa, a outra cai aqui.
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        }
        await EnsureClienteAsync(req.NomeCliente, req.EmailCliente);
        ag.Quadra = quadra;
        return CreatedAtAction(nameof(Obter), new { id = ag.Id }, Map(ag));
    }

    // ----- Disponibilidade (público) -----
    [HttpGet("disponibilidade")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<DisponibilidadeSlot>>> Disponibilidade(
        [FromQuery] Guid quadraId,
        [FromQuery] DateTime dia)
    {
        var quadra = await _db.Quadras.AsNoTracking().FirstOrDefaultAsync(q => q.Id == quadraId);
        if (quadra is null) return NotFound(new { erro = "Quadra não encontrada." });

        // Horários montados no fuso do estabelecimento e convertidos para UTC — não
        // dependem do fuso do processo do servidor (o cliente reconverte ao exibir).
        var inicioDia = Horario.LocalParaUtc(dia.Year, dia.Month, dia.Day, quadra.HoraAbertura, _fuso);
        var fimDia = Horario.LocalParaUtc(dia.Year, dia.Month, dia.Day, quadra.HoraFechamento, _fuso);

        var reservas = await _db.Agendamentos.AsNoTracking()
            .Where(a => a.QuadraId == quadraId &&
                        a.Status != StatusAgendamento.Cancelado &&
                        a.Inicio < fimDia && a.Fim > inicioDia)
            .ToListAsync();

        var bloqueios = await _db.Bloqueios.AsNoTracking()
            .Where(b => b.QuadraId == quadraId && b.Inicio < fimDia && b.Fim > inicioDia)
            .ToListAsync();

        var agoraUtc = DateTime.UtcNow;
        var slots = new List<DisponibilidadeSlot>();
        for (var h = inicioDia; h < fimDia; h = h.AddHours(1))
        {
            var slotFim = h.AddHours(1);
            var ocupado = reservas.Any(r => h < r.Fim && r.Inicio < slotFim)
                || bloqueios.Any(b => h < b.Fim && b.Inicio < slotFim)
                || slotFim <= agoraUtc;
            slots.Add(new DisponibilidadeSlot(h, slotFim, !ocupado));
        }
        return Ok(slots);
    }

    // ----- Interno: listar -----
    [HttpGet]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<IEnumerable<AgendamentoDto>>> Listar(
        [FromQuery] DateTime? de,
        [FromQuery] DateTime? ate,
        [FromQuery] Guid? quadraId,
        [FromQuery] StatusAgendamento? status,
        [FromQuery] int? page,
        [FromQuery] int? pageSize)
    {
        var query = _db.Agendamentos.AsNoTracking().Include(a => a.Quadra).AsQueryable();
        if (de is not null) query = query.Where(a => a.Inicio >= de);
        if (ate is not null) query = query.Where(a => a.Inicio <= ate);
        if (quadraId is not null) query = query.Where(a => a.QuadraId == quadraId);
        if (status is not null) query = query.Where(a => a.Status == status);

        var pg = Paginacao.De(page, pageSize, padrao: 200, max: 500);
        Response.Headers["X-Total-Count"] = (await query.CountAsync()).ToString();

        var itens = await query.OrderByDescending(a => a.Inicio)
            .Skip(pg.Skip).Take(pg.PageSize)
            .Select(a => Map(a)).ToListAsync();
        return Ok(itens);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<AgendamentoDto>> Obter(Guid id)
    {
        var a = await _db.Agendamentos.Include(x => x.Quadra)
            .FirstOrDefaultAsync(x => x.Id == id);
        return a is null ? NotFound() : Ok(Map(a));
    }

    // ----- Interno: criar (já confirmado) -----
    [HttpPost]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<AgendamentoDto>> Criar(AgendamentoCreateRequest req)
    {
        if (req.Fim <= req.Inicio)
            return BadRequest(new { erro = "Horário final deve ser maior que o inicial." });

        var quadra = await _db.Quadras.FindAsync(req.QuadraId);
        if (quadra is null) return BadRequest(new { erro = "Quadra inexistente." });

        if (await _svc.ExisteConflitoAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        if (await _svc.ExisteBloqueioAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Quadra bloqueada nesse horário. Remova o bloqueio para reservar." });

        var bruto = AgendamentoService.CalcularValor(quadra.PrecoHora, req.Inicio, req.Fim);
        var (cupom, desconto, erroCupom) = await _svc.ResolverCupomAsync(req.CupomCodigo, bruto);
        if (erroCupom is not null) return BadRequest(new { erro = erroCupom });

        var ag = new Agendamento
        {
            QuadraId = req.QuadraId,
            Inicio = req.Inicio,
            Fim = req.Fim,
            NomeCliente = req.NomeCliente,
            TelefoneCliente = req.TelefoneCliente,
            EmailCliente = req.EmailCliente,
            Observacoes = req.Observacoes,
            Status = req.Status,
            ValorTotal = bruto - desconto,
            ValorDesconto = desconto,
            CupomId = cupom?.Id,
            CupomCodigo = cupom?.Codigo,
            CriadoPorUserId = UsuarioAtual(),
        };
        _db.Agendamentos.Add(ag);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (PgErros.EhOverlap(ex))
        {
            // Rede de segurança da constraint de exclusão: duas reservas concorrentes
            // do mesmo horário — só uma passa, a outra cai aqui.
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        }
        await EnsureClienteAsync(req.NomeCliente, req.EmailCliente);
        ag.Quadra = quadra;
        return CreatedAtAction(nameof(Obter), new { id = ag.Id }, Map(ag));
    }

    // ----- Professor: reservar quadra para dar aula -----
    [HttpPost("aula")]
    [Authorize(Roles = Roles.Professor)]
    public async Task<ActionResult<AgendamentoDto>> ReservarAula(AgendamentoAulaRequest req)
    {
        if (req.Fim <= req.Inicio)
            return BadRequest(new { erro = "Horário final deve ser maior que o inicial." });
        if (req.Inicio < DateTime.UtcNow.AddMinutes(-1))
            return BadRequest(new { erro = "Não é possível agendar no passado." });

        var profId = UsuarioAtual();
        if (profId is null) return Unauthorized();
        var professor = await _userManager.FindByIdAsync(profId.Value.ToString());
        if (professor is null || !professor.Ativo)
            return Unauthorized();

        var quadra = await _db.Quadras.FindAsync(req.QuadraId);
        if (quadra is null || !quadra.Ativa)
            return BadRequest(new { erro = "Quadra indisponível." });

        if (await _svc.ExisteConflitoAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        if (await _svc.ExisteBloqueioAsync(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Quadra bloqueada nesse horário." });

        var valor = AgendamentoService.CalcularValor(professor.PrecoAula, req.Inicio, req.Fim);

        var obs = string.IsNullOrWhiteSpace(req.Observacoes)
            ? "Aula"
            : $"Aula — {req.Observacoes.Trim()}";

        var ag = new Agendamento
        {
            QuadraId = req.QuadraId,
            Inicio = req.Inicio,
            Fim = req.Fim,
            NomeCliente = professor.NomeCompleto,
            TelefoneCliente = professor.PhoneNumber ?? "",
            EmailCliente = professor.Email ?? "",
            Observacoes = obs,
            Status = StatusAgendamento.Confirmado,
            ValorTotal = valor,
            ValorDesconto = 0m,
            CriadoPorUserId = profId,
        };
        _db.Agendamentos.Add(ag);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (PgErros.EhOverlap(ex))
        {
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        }
        ag.Quadra = quadra;
        return CreatedAtAction(nameof(Obter), new { id = ag.Id }, Map(ag));
    }

    // ----- Interno: alterar status -----
    [HttpPatch("{id:guid}/status")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<AgendamentoDto>> AlterarStatus(Guid id, AgendamentoStatusRequest req)
    {
        var a = await _db.Agendamentos.Include(x => x.Quadra)
            .FirstOrDefaultAsync(x => x.Id == id);
        if (a is null) return NotFound();

        a.Status = req.Status;
        await _db.SaveChangesAsync();
        return Ok(Map(a));
    }
}
