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
[Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
public class VendasController : ControllerBase
{
    private readonly AppDbContext _db;
    public VendasController(AppDbContext db) => _db = db;

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static VendaDto Map(Venda v) =>
        new(v.Id, v.Total, v.FormaPagamento, v.NomeCliente, v.CriadoEm,
            v.Itens.Select(i => new VendaItemDto(i.ProdutoId, i.ProdutoNome, i.Quantidade, i.PrecoUnitario, i.Subtotal)));

    [HttpGet]
    public async Task<ActionResult<IEnumerable<VendaDto>>> Listar([FromQuery] Guid? caixaId)
    {
        var query = _db.Vendas.AsNoTracking().Include(v => v.Itens).AsQueryable();
        if (caixaId is not null) query = query.Where(v => v.CaixaId == caixaId);
        var itens = await query.OrderByDescending(v => v.CriadoEm).Take(200).ToListAsync();
        return Ok(itens.Select(Map));
    }

    [HttpPost]
    public async Task<ActionResult<VendaDto>> Registrar(VendaCreateRequest req)
    {
        var caixa = await _db.Caixas.FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto);
        if (caixa is null)
            return BadRequest(new { erro = "Abra o caixa antes de registrar vendas." });

        var idsProdutos = req.Itens.Select(i => i.ProdutoId).Distinct().ToList();
        var produtos = await _db.Produtos.Where(p => idsProdutos.Contains(p.Id)).ToListAsync();

        await using var tx = await _db.Database.BeginTransactionAsync();

        var venda = new Venda
        {
            CaixaId = caixa.Id,
            FormaPagamento = req.FormaPagamento,
            NomeCliente = req.NomeCliente,
            RegistradoPorUserId = UsuarioAtual(),
        };

        decimal total = 0;
        foreach (var item in req.Itens)
        {
            if (item.Quantidade <= 0)
                return BadRequest(new { erro = "Quantidade inválida." });

            var produto = produtos.FirstOrDefault(p => p.Id == item.ProdutoId);
            if (produto is null || !produto.Ativo)
                return BadRequest(new { erro = $"Produto {item.ProdutoId} indisponível." });

            // Baixa de estoque atômica: o WHERE só decrementa se ainda houver saldo, e o
            // UPDATE trava a linha. Duas vendas simultâneas do mesmo produto não conseguem
            // vender além do disponível — a que ficar sem saldo recebe 0 linhas afetadas.
            var baixou = await _db.Produtos
                .Where(p => p.Id == produto.Id && p.EstoqueQuantidade >= item.Quantidade)
                .ExecuteUpdateAsync(s => s.SetProperty(
                    p => p.EstoqueQuantidade, p => p.EstoqueQuantidade - item.Quantidade));
            if (baixou == 0)
                return BadRequest(new { erro = $"Estoque insuficiente para {produto.Nome}." });

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

        // Entrada no caixa referente à venda
        _db.MovimentacoesCaixa.Add(new MovimentacaoCaixa
        {
            CaixaId = caixa.Id,
            Tipo = TipoMovimentacao.Entrada,
            Categoria = "Venda",
            Valor = total,
            Descricao = $"Venda de produtos ({venda.Itens.Count} item(ns))",
            FormaPagamento = req.FormaPagamento,
            VendaId = venda.Id,
            RegistradoPorUserId = UsuarioAtual(),
        });

        await _db.SaveChangesAsync();
        await tx.CommitAsync();
        return CreatedAtAction(nameof(Listar), new { }, Map(venda));
    }
}
