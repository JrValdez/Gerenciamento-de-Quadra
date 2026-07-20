using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

/// <summary>Análises financeiras do caixa. Somente Admin.</summary>
[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = Roles.Admin)]
public class AnaliseController : ControllerBase
{
    private readonly AppDbContext _db;
    public AnaliseController(AppDbContext db) => _db = db;

    private const int DiasGrafico = 14;

    [HttpGet("caixa")]
    public async Task<ActionResult<AnaliseCaixaDto>> Caixa(CancellationToken ct)
    {
        var hojeLocal = DateTime.Now.Date;

        // Início da semana (segunda-feira) e do mês, em hora local.
        var diff = (int)hojeLocal.DayOfWeek - (int)DayOfWeek.Monday;
        if (diff < 0) diff += 7;
        var inicioSemanaLocal = hojeLocal.AddDays(-diff);
        var inicioMesLocal = new DateTime(hojeLocal.Year, hojeLocal.Month, 1);
        var inicioGraficoLocal = hojeLocal.AddDays(-(DiasGrafico - 1));

        // Janela de consulta: a mais antiga entre início do mês e início do gráfico.
        var janelaLocal = inicioMesLocal < inicioGraficoLocal ? inicioMesLocal : inicioGraficoLocal;
        var janelaUtc = janelaLocal.ToUniversalTime();

        var movs = await _db.MovimentacoesCaixa.AsNoTracking()
            .Where(m => m.CriadoEm >= janelaUtc)
            .ToListAsync(ct);

        var inicioDiaUtc = hojeLocal.ToUniversalTime();
        var inicioSemanaUtc = inicioSemanaLocal.ToUniversalTime();
        var inicioMesUtc = inicioMesLocal.ToUniversalTime();

        PeriodoResumo Resumo(DateTime desdeUtc)
        {
            var lista = movs.Where(m => m.CriadoEm >= desdeUtc).ToList();
            var e = lista.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
            var s = lista.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
            return new PeriodoResumo(e, s, e - s, lista.Count);
        }

        // Fluxo diário dos últimos DiasGrafico dias (preenche dias sem movimento com zero).
        var porDia = movs
            .Where(m => m.CriadoEm >= inicioGraficoLocal.ToUniversalTime())
            .GroupBy(m => m.CriadoEm.ToLocalTime().Date)
            .ToDictionary(g => g.Key, g => g.ToList());

        var fluxo = new List<FluxoDia>();
        for (var d = inicioGraficoLocal; d <= hojeLocal; d = d.AddDays(1))
        {
            var e = 0m; var s = 0m;
            if (porDia.TryGetValue(d, out var doDia))
            {
                e = doDia.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
                s = doDia.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
            }
            fluxo.Add(new FluxoDia(d, e, s, e - s));
        }

        // Quebra por categoria e forma de pagamento (no mês).
        var doMes = movs.Where(m => m.CriadoEm >= inicioMesUtc).ToList();

        var porCategoria = doMes
            .GroupBy(m => m.Categoria)
            .Select(g => new CategoriaResumo(
                g.Key,
                g.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor),
                g.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor)))
            .OrderByDescending(c => c.Entradas + c.Saidas)
            .ToList();

        var porForma = doMes
            .Where(m => m.Tipo == TipoMovimentacao.Entrada)
            .GroupBy(m => m.FormaPagamento)
            .Select(g => new FormaPagamentoResumo(g.Key.ToString(), g.Sum(m => m.Valor)))
            .OrderByDescending(f => f.Total)
            .ToList();

        // Saldo do caixa aberto (se houver).
        var caixa = await _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto, ct);
        decimal? saldo = null;
        if (caixa is not null)
        {
            var entradas = caixa.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
            var saidas = caixa.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
            saldo = caixa.ValorAbertura + entradas - saidas;
        }

        return Ok(new AnaliseCaixaDto(
            Resumo(inicioDiaUtc),
            Resumo(inicioSemanaUtc),
            Resumo(inicioMesUtc),
            caixa is not null,
            saldo,
            fluxo,
            porCategoria,
            porForma));
    }
}
