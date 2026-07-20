using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Services;

/// <summary>
/// Regras da sessão de caixa: abertura (garantindo um único caixa aberto), fechamento,
/// lançamento de movimentações e cálculo do saldo esperado. Deixa o controller apenas
/// com o mapeamento HTTP, no mesmo espírito de <see cref="AgendamentoService"/>.
/// </summary>
public class CaixaService
{
    private readonly AppDbContext _db;
    public CaixaService(AppDbContext db) => _db = db;

    /// <summary>Totais de uma sessão: entradas, saídas e saldo esperado (abertura + entradas − saídas).</summary>
    public static (decimal entradas, decimal saidas, decimal saldo) Totais(Caixa c)
    {
        var entradas = c.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
        var saidas = c.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
        return (entradas, saidas, c.ValorAbertura + entradas - saidas);
    }

    /// <summary>Caixa aberto no momento (com movimentações), ou null se não houver.</summary>
    public Task<Caixa?> AtualAsync(CancellationToken ct = default) =>
        _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto, ct);

    /// <summary>
    /// Abre um caixa. <c>conflito</c> = true quando já existe um aberto (o controller
    /// mapeia para 409). A checagem inicial é para a UX; o índice único parcial (só um
    /// caixa Aberto) é a garantia real caso duas aberturas cheguem ao mesmo tempo.
    /// </summary>
    public async Task<(Caixa? caixa, string? erro, bool conflito)> AbrirAsync(
        AbrirCaixaRequest req, Guid usuarioId, CancellationToken ct = default)
    {
        if (await _db.Caixas.AnyAsync(c => c.Status == StatusCaixa.Aberto, ct))
            return (null, "Já existe um caixa aberto.", true);

        var caixa = new Caixa
        {
            ValorAbertura = req.ValorAbertura,
            Observacoes = req.Observacoes,
            AbertoPorUserId = usuarioId,
            Status = StatusCaixa.Aberto,
        };
        _db.Caixas.Add(caixa);
        try
        {
            await _db.SaveChangesAsync(ct);
        }
        catch (DbUpdateException ex) when (PgErros.EhViolacaoUnica(ex))
        {
            return (null, "Já existe um caixa aberto.", true);
        }
        return (caixa, null, false);
    }

    /// <summary>Fecha o caixa aberto, registrando quem fechou e o valor contado.</summary>
    public async Task<(Caixa? caixa, string? erro)> FecharAsync(
        FecharCaixaRequest req, Guid usuarioId, CancellationToken ct = default)
    {
        var caixa = await _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto, ct);
        if (caixa is null) return (null, "Não há caixa aberto.");

        caixa.Status = StatusCaixa.Fechado;
        caixa.FechadoEm = DateTime.UtcNow;
        caixa.FechadoPorUserId = usuarioId;
        caixa.ValorFechamentoInformado = req.ValorFechamentoInformado;
        if (req.Observacoes is not null) caixa.Observacoes = req.Observacoes;
        await _db.SaveChangesAsync(ct);
        return (caixa, null);
    }

    /// <summary>Lança uma movimentação manual (sangria, suprimento, entrada/saída avulsa) no caixa aberto.</summary>
    public async Task<(MovimentacaoCaixa? mov, string? erro)> LancarMovimentacaoAsync(
        MovimentacaoCreateRequest req, Guid usuarioId, CancellationToken ct = default)
    {
        var caixa = await _db.Caixas.FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto, ct);
        if (caixa is null) return (null, "Não há caixa aberto.");

        var mov = new MovimentacaoCaixa
        {
            CaixaId = caixa.Id,
            Tipo = req.Tipo,
            Categoria = req.Categoria,
            Valor = req.Valor,
            Descricao = req.Descricao,
            FormaPagamento = req.FormaPagamento,
            RegistradoPorUserId = usuarioId,
        };
        _db.MovimentacoesCaixa.Add(mov);
        await _db.SaveChangesAsync(ct);
        return (mov, null);
    }
}
