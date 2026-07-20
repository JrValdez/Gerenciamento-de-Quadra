using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Services;

/// <summary>
/// Regras da venda de balcão: valida o caixa aberto, baixa o estoque de forma atômica,
/// monta a venda e lança a entrada correspondente no caixa — tudo numa transação. Tira
/// a lógica do controller e a torna testável, no mesmo espírito de <see cref="AgendamentoService"/>.
/// </summary>
public class VendaService
{
    private readonly AppDbContext _db;
    public VendaService(AppDbContext db) => _db = db;

    /// <summary>
    /// Registra uma venda de produtos. Retorna a venda criada ou uma mensagem de erro
    /// de negócio (caixa fechado, produto indisponível, estoque insuficiente) — nesse
    /// caso a transação é desfeita e nada é persistido.
    /// </summary>
    public async Task<(Venda? venda, string? erro)> RegistrarAsync(
        VendaCreateRequest req, Guid usuarioId, CancellationToken ct = default)
    {
        var caixa = await _db.Caixas.FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto, ct);
        if (caixa is null)
            return (null, "Abra o caixa antes de registrar vendas.");

        var idsProdutos = req.Itens.Select(i => i.ProdutoId).Distinct().ToList();
        var produtos = await _db.Produtos.Where(p => idsProdutos.Contains(p.Id)).ToListAsync(ct);

        await using var tx = await _db.Database.BeginTransactionAsync(ct);

        var venda = new Venda
        {
            CaixaId = caixa.Id,
            FormaPagamento = req.FormaPagamento,
            NomeCliente = req.NomeCliente,
            RegistradoPorUserId = usuarioId,
        };

        decimal total = 0;
        foreach (var item in req.Itens)
        {
            if (item.Quantidade <= 0)
                return (null, "Quantidade inválida.");

            var produto = produtos.FirstOrDefault(p => p.Id == item.ProdutoId);
            if (produto is null || !produto.Ativo)
                return (null, $"Produto {item.ProdutoId} indisponível.");

            // Baixa de estoque atômica: o WHERE só decrementa se ainda houver saldo, e o
            // UPDATE trava a linha. Duas vendas simultâneas do mesmo produto não conseguem
            // vender além do disponível — a que ficar sem saldo recebe 0 linhas afetadas.
            var baixou = await _db.Produtos
                .Where(p => p.Id == produto.Id && p.EstoqueQuantidade >= item.Quantidade)
                .ExecuteUpdateAsync(s => s.SetProperty(
                    p => p.EstoqueQuantidade, p => p.EstoqueQuantidade - item.Quantidade), ct);
            if (baixou == 0)
                return (null, $"Estoque insuficiente para {produto.Nome}.");

            var subtotal = Math.Round(produto.Preco * item.Quantidade, 2);
            total += subtotal;

            venda.Itens.Add(new VendaItem
            {
                ProdutoId = produto.Id,
                ProdutoNome = produto.Nome,
                Quantidade = item.Quantidade,
                PrecoUnitario = produto.Preco,
                Subtotal = subtotal,
            });
        }

        venda.Total = total;
        _db.Vendas.Add(venda);

        // Entrada no caixa referente à venda.
        _db.MovimentacoesCaixa.Add(new MovimentacaoCaixa
        {
            CaixaId = caixa.Id,
            Tipo = TipoMovimentacao.Entrada,
            Categoria = "Venda",
            Valor = total,
            Descricao = $"Venda de produtos ({venda.Itens.Count} item(ns))",
            FormaPagamento = req.FormaPagamento,
            VendaId = venda.Id,
            RegistradoPorUserId = usuarioId,
        });

        await _db.SaveChangesAsync(ct);
        await tx.CommitAsync(ct);
        return (venda, null);
    }
}
