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
public class BloqueiosController : ControllerBase
{
    private readonly AppDbContext _db;
    public BloqueiosController(AppDbContext db) => _db = db;

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static BloqueioDto Map(Bloqueio b) =>
        new(b.Id, b.QuadraId, b.Quadra?.Nome ?? "", b.Inicio, b.Fim, b.Motivo);

    /// <summary>Lista bloqueios (por padrão os que ainda não terminaram).</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<BloqueioDto>>> Listar(
        [FromQuery] Guid? quadraId,
        [FromQuery] bool incluirPassados = false)
    {
        var query = _db.Bloqueios.AsNoTracking().Include(b => b.Quadra).AsQueryable();
        if (quadraId is not null) query = query.Where(b => b.QuadraId == quadraId);
        if (!incluirPassados) query = query.Where(b => b.Fim >= DateTime.UtcNow);

        var itens = await query.OrderBy(b => b.Inicio).Select(b => Map(b)).ToListAsync();
        return Ok(itens);
    }

    [HttpPost]
    public async Task<ActionResult<BloqueioDto>> Criar(BloqueioCreateRequest req)
    {
        if (req.Fim <= req.Inicio)
            return BadRequest(new { erro = "Fim deve ser maior que o início." });

        var quadra = await _db.Quadras.FindAsync(req.QuadraId);
        if (quadra is null) return BadRequest(new { erro = "Quadra inexistente." });

        var bloqueio = new Bloqueio
        {
            QuadraId = req.QuadraId,
            Inicio = req.Inicio.ToUniversalTime(),
            Fim = req.Fim.ToUniversalTime(),
            Motivo = req.Motivo,
            CriadoPorUserId = UsuarioAtual(),
        };
        _db.Bloqueios.Add(bloqueio);
        await _db.SaveChangesAsync();
        bloqueio.Quadra = quadra;
        return Ok(Map(bloqueio));
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Excluir(Guid id)
    {
        var b = await _db.Bloqueios.FindAsync(id);
        if (b is null) return NotFound();
        _db.Bloqueios.Remove(b);
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
