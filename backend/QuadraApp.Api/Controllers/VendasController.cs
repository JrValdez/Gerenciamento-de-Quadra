using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
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
[Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
public class VendasController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly VendaService _svc;
    public VendasController(AppDbContext db, VendaService svc)
    {
        _db = db;
        _svc = svc;
    }

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static VendaDto Map(Venda v) =>
        new(v.Id, v.Total, v.FormaPagamento, v.NomeCliente, v.CriadoEm,
            v.Itens.Select(i => new VendaItemDto(i.ProdutoId, i.ProdutoNome, i.Quantidade, i.PrecoUnitario, i.Subtotal)));

    [HttpGet]
    public async Task<ActionResult<IEnumerable<VendaDto>>> Listar(
        [FromQuery] Guid? caixaId, [FromQuery] int? page, [FromQuery] int? pageSize,
        CancellationToken ct = default)
    {
        var query = _db.Vendas.AsNoTracking().Include(v => v.Itens).AsQueryable();
        if (caixaId is not null) query = query.Where(v => v.CaixaId == caixaId);

        var pg = Paginacao.De(page, pageSize, padrao: 200, max: 500);
        Response.Headers["X-Total-Count"] = (await query.CountAsync(ct)).ToString();

        var itens = await query.OrderByDescending(v => v.CriadoEm)
            .Skip(pg.Skip).Take(pg.PageSize).ToListAsync(ct);
        return Ok(itens.Select(Map));
    }

    [HttpPost]
    public async Task<ActionResult<VendaDto>> Registrar(VendaCreateRequest req, CancellationToken ct)
    {
        var (venda, erro) = await _svc.RegistrarAsync(req, UsuarioAtual(), ct);
        if (erro is not null) return BadRequest(new { erro });
        return CreatedAtAction(nameof(Listar), new { }, Map(venda!));
    }
}
