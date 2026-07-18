using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
public class DashboardController : ControllerBase
{
    private readonly AppDbContext _db;
    public DashboardController(AppDbContext db) => _db = db;

    private const int LimiteBaixoEstoque = 5;

    [HttpGet("resumo")]
    public async Task<ActionResult<DashboardResumo>> Resumo()
    {
        // "Hoje" no fuso do servidor, convertido para UTC (dados são armazenados em UTC).
        var hojeLocal = DateTime.Now.Date;
        var inicioUtc = hojeLocal.ToUniversalTime();
        var fimUtc = hojeLocal.AddDays(1).ToUniversalTime();
        var agoraUtc = DateTime.UtcNow;

        var doDia = await _db.Agendamentos.AsNoTracking()
            .Where(a => a.Inicio >= inicioUtc && a.Inicio < fimUtc && a.Status != StatusAgendamento.Cancelado)
            .ToListAsync();

        var agendamentosHoje = doDia.Count;
        var faturamentoHoje = doDia
            .Where(a => a.Status == StatusAgendamento.Confirmado || a.Status == StatusAgendamento.Concluido)
            .Sum(a => a.ValorTotal);

        var pendentes = await _db.Agendamentos.CountAsync(a => a.Status == StatusAgendamento.Pendente);

        var caixa = await _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto);
        decimal? saldo = null;
        if (caixa is not null)
        {
            var entradas = caixa.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
            var saidas = caixa.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
            saldo = caixa.ValorAbertura + entradas - saidas;
        }

        var baixoEstoque = await _db.Produtos
            .CountAsync(p => p.Ativo && p.EstoqueQuantidade <= LimiteBaixoEstoque);

        var proximos = await _db.Agendamentos.AsNoTracking().Include(a => a.Quadra)
            .Where(a => a.Inicio >= agoraUtc && a.Status != StatusAgendamento.Cancelado)
            .OrderBy(a => a.Inicio)
            .Take(6)
            .Select(a => new AgendamentoDto(a.Id, a.QuadraId, a.Quadra!.Nome, a.Inicio, a.Fim,
                a.NomeCliente, a.TelefoneCliente, a.EmailCliente, a.Status, a.ValorTotal, a.Observacoes, a.CriadoEm))
            .ToListAsync();

        return Ok(new DashboardResumo(
            agendamentosHoje, pendentes, faturamentoHoje,
            caixa is not null, saldo, baixoEstoque, proximos));
    }
}
