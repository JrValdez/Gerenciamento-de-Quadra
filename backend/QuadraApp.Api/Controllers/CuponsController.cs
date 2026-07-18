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
public class CuponsController : ControllerBase
{
    private readonly AppDbContext _db;
    public CuponsController(AppDbContext db) => _db = db;

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static CupomDto Map(Cupom c) =>
        new(c.Id, c.Codigo, c.Descricao, c.Tipo, c.Valor, c.ValidoAte, c.Ativo,
            c.Ativo && c.ValidoAte >= DateTime.UtcNow);

    /// <summary>Valida regras de negócio comuns a criação e edição.</summary>
    private static string? Validar(TipoDesconto tipo, decimal valor)
    {
        if (tipo == TipoDesconto.Percentual && valor > 100)
            return "Desconto percentual não pode ser maior que 100%.";
        return null;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CupomDto>>> Listar([FromQuery] bool incluirInativos = false)
    {
        var query = _db.Cupons.AsNoTracking().AsQueryable();
        if (!incluirInativos) query = query.Where(c => c.Ativo);
        var itens = await query.OrderByDescending(c => c.CriadoEm).Select(c => Map(c)).ToListAsync();
        return Ok(itens);
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<CupomDto>> Obter(Guid id)
    {
        var c = await _db.Cupons.FindAsync(id);
        return c is null ? NotFound() : Ok(Map(c));
    }

    /// <summary>
    /// Valida um cupom pelo código (usado na reserva, inclusive pública).
    /// Retorna o cupom apenas se estiver ativo e dentro do prazo.
    /// </summary>
    [HttpGet("validar/{codigo}")]
    [AllowAnonymous]
    public async Task<ActionResult<CupomDto>> Validar(string codigo)
    {
        var cod = (codigo ?? "").Trim().ToUpperInvariant();
        var c = await _db.Cupons.AsNoTracking().FirstOrDefaultAsync(x => x.Codigo == cod);
        if (c is null) return NotFound(new { erro = "Cupom não encontrado." });
        if (!(c.Ativo && c.ValidoAte >= DateTime.UtcNow))
            return BadRequest(new { erro = "Cupom expirado ou inativo." });
        return Ok(Map(c));
    }

    [HttpPost]
    public async Task<ActionResult<CupomDto>> Criar(CupomCreateRequest req)
    {
        var erro = Validar(req.Tipo, req.Valor);
        if (erro is not null) return BadRequest(new { erro });

        var codigo = req.Codigo.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(codigo))
            return BadRequest(new { erro = "Código é obrigatório." });

        if (await _db.Cupons.AnyAsync(c => c.Codigo == codigo))
            return BadRequest(new { erro = "Já existe um cupom com esse código." });

        var cupom = new Cupom
        {
            Codigo = codigo,
            Descricao = req.Descricao,
            Tipo = req.Tipo,
            Valor = req.Valor,
            ValidoAte = req.ValidoAte.ToUniversalTime(),
            Ativo = req.Ativo,
            CriadoPorUserId = UsuarioAtual(),
        };
        _db.Cupons.Add(cupom);
        await _db.SaveChangesAsync();
        return CreatedAtAction(nameof(Obter), new { id = cupom.Id }, Map(cupom));
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<CupomDto>> Atualizar(Guid id, CupomUpdateRequest req)
    {
        var cupom = await _db.Cupons.FindAsync(id);
        if (cupom is null) return NotFound();

        var erro = Validar(req.Tipo, req.Valor);
        if (erro is not null) return BadRequest(new { erro });

        var codigo = req.Codigo.Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(codigo))
            return BadRequest(new { erro = "Código é obrigatório." });

        if (await _db.Cupons.AnyAsync(c => c.Codigo == codigo && c.Id != id))
            return BadRequest(new { erro = "Já existe um cupom com esse código." });

        cupom.Codigo = codigo;
        cupom.Descricao = req.Descricao;
        cupom.Tipo = req.Tipo;
        cupom.Valor = req.Valor;
        cupom.ValidoAte = req.ValidoAte.ToUniversalTime();
        cupom.Ativo = req.Ativo;
        await _db.SaveChangesAsync();
        return Ok(Map(cupom));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var c = await _db.Cupons.FindAsync(id);
        if (c is null) return NotFound();
        _db.Cupons.Remove(c);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
