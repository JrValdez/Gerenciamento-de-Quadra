using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AgendamentosController : ControllerBase
{
    private readonly AppDbContext _db;
    public AgendamentosController(AppDbContext db) => _db = db;

    private static AgendamentoDto Map(Agendamento a) =>
        new(a.Id, a.QuadraId, a.Quadra?.Nome ?? "", a.Inicio, a.Fim,
            a.NomeCliente, a.TelefoneCliente, a.EmailCliente,
            a.Status, a.ValorTotal, a.Observacoes, a.CriadoEm,
            a.ValorDesconto, a.CupomCodigo);

    /// <summary>
    /// Resolve e valida um cupom para um valor bruto. Retorna o cupom, o desconto a abater
    /// e uma mensagem de erro (quando o código foi informado mas é inválido/expirado).
    /// </summary>
    private async Task<(Cupom? cupom, decimal desconto, string? erro)> ResolverCupomAsync(
        string? codigo, decimal bruto)
    {
        if (string.IsNullOrWhiteSpace(codigo)) return (null, 0m, null);

        var cod = codigo.Trim().ToUpperInvariant();
        var cupom = await _db.Cupons.FirstOrDefaultAsync(c => c.Codigo == cod);
        if (cupom is null) return (null, 0m, "Cupom não encontrado.");
        if (!cupom.Ativo) return (null, 0m, "Cupom inativo.");
        if (cupom.ValidoAte < DateTime.UtcNow) return (null, 0m, "Cupom expirado.");

        var desconto = cupom.Tipo == TipoDesconto.Percentual
            ? Math.Round(bruto * cupom.Valor / 100m, 2)
            : cupom.Valor;
        if (desconto > bruto) desconto = bruto;
        return (cupom, desconto, null);
    }

    private Guid? UsuarioAtual()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return Guid.TryParse(id, out var g) ? g : null;
    }

    private async Task<bool> ExisteConflito(Guid quadraId, DateTime inicio, DateTime fim, Guid? ignorarId = null)
    {
        return await _db.Agendamentos.AnyAsync(a =>
            a.QuadraId == quadraId &&
            a.Status != StatusAgendamento.Cancelado &&
            (ignorarId == null || a.Id != ignorarId) &&
            inicio < a.Fim && a.Inicio < fim);
    }

    private static decimal CalcularValor(Quadra quadra, DateTime inicio, DateTime fim)
    {
        var horas = (decimal)(fim - inicio).TotalHours;
        return Math.Round(quadra.PrecoHora * horas, 2);
    }

    private async Task<bool> ExisteBloqueio(Guid quadraId, DateTime inicio, DateTime fim) =>
        await _db.Bloqueios.AnyAsync(b =>
            b.QuadraId == quadraId && inicio < b.Fim && b.Inicio < fim);

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

        if (await ExisteConflito(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        if (await ExisteBloqueio(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Quadra bloqueada nesse horário." });

        var bruto = CalcularValor(quadra, req.Inicio, req.Fim);
        var (cupom, desconto, erroCupom) = await ResolverCupomAsync(req.CupomCodigo, bruto);
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
        await _db.SaveChangesAsync();
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

        // Horários montados em hora local do servidor e convertidos para UTC
        // (o cliente reconverte para o fuso local ao exibir).
        var inicioDia = new DateTime(dia.Year, dia.Month, dia.Day, quadra.HoraAbertura, 0, 0, DateTimeKind.Local)
            .ToUniversalTime();
        var fimDia = new DateTime(dia.Year, dia.Month, dia.Day, quadra.HoraFechamento, 0, 0, DateTimeKind.Local)
            .ToUniversalTime();

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
        [FromQuery] StatusAgendamento? status)
    {
        var query = _db.Agendamentos.AsNoTracking().Include(a => a.Quadra).AsQueryable();
        if (de is not null) query = query.Where(a => a.Inicio >= de);
        if (ate is not null) query = query.Where(a => a.Inicio <= ate);
        if (quadraId is not null) query = query.Where(a => a.QuadraId == quadraId);
        if (status is not null) query = query.Where(a => a.Status == status);

        var itens = await query.OrderByDescending(a => a.Inicio)
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

        if (await ExisteConflito(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Já existe reserva nesse horário." });
        if (await ExisteBloqueio(req.QuadraId, req.Inicio, req.Fim))
            return Conflict(new { erro = "Quadra bloqueada nesse horário. Remova o bloqueio para reservar." });

        var bruto = CalcularValor(quadra, req.Inicio, req.Fim);
        var (cupom, desconto, erroCupom) = await ResolverCupomAsync(req.CupomCodigo, bruto);
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
        await _db.SaveChangesAsync();
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
