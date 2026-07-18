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
public class ProdutosController : ControllerBase
{
    private readonly AppDbContext _db;
    public ProdutosController(AppDbContext db) => _db = db;

    private static ProdutoDto Map(Produto p) =>
        new(p.Id, p.Nome, p.Descricao, p.Categoria, p.Preco, p.EstoqueQuantidade, p.Ativo);

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProdutoDto>>> Listar([FromQuery] bool incluirInativos = false)
    {
        var query = _db.Produtos.AsNoTracking().AsQueryable();
        if (!incluirInativos) query = query.Where(p => p.Ativo);
        var itens = await query.OrderBy(p => p.Nome).Select(p => Map(p)).ToListAsync();
        return Ok(itens);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ProdutoDto>> Obter(Guid id)
    {
        var p = await _db.Produtos.FindAsync(id);
        return p is null ? NotFound() : Ok(Map(p));
    }

    [HttpPost]
    public async Task<ActionResult<ProdutoDto>> Criar(ProdutoCreateRequest req)
    {
        var p = new Produto
        {
            Nome = req.Nome,
            Descricao = req.Descricao,
            Categoria = req.Categoria,
            Preco = req.Preco,
            EstoqueQuantidade = req.EstoqueQuantidade,
            Ativo = req.Ativo,
        };
        _db.Produtos.Add(p);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = p.Id }, Map(p));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ProdutoDto>> Atualizar(Guid id, ProdutoUpdateRequest req)
    {
        var p = await _db.Produtos.FindAsync(id);
        if (p is null) return NotFound();

        p.Nome = req.Nome;
        p.Descricao = req.Descricao;
        p.Categoria = req.Categoria;
        p.Preco = req.Preco;
        p.EstoqueQuantidade = req.EstoqueQuantidade;
        p.Ativo = req.Ativo;
        await _db.SaveChangesAsync();
        return Ok(Map(p));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var p = await _db.Produtos.FindAsync(id);
        if (p is null) return NotFound();

        var vendido = await _db.VendaItens.AnyAsync(i => i.ProdutoId == id);
        if (vendido)
        {
            p.Ativo = false;
            await _db.SaveChangesAsync();
            return Ok(new { mensagem = "Produto já vendido; foi inativado em vez de excluído." });
        }

        _db.Produtos.Remove(p);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
