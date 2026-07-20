using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // qualquer usuário logado pode listar; escrita restrita abaixo
public class ModalidadesController : ControllerBase
{
    private readonly AppDbContext _db;
    public ModalidadesController(AppDbContext db) => _db = db;

    private static ModalidadeDto Map(Modalidade m) => new(m.Id, m.Nome, m.Ativa);

    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<ModalidadeDto>>> Listar(
        [FromQuery] bool incluirInativas = false, CancellationToken ct = default)
    {
        var query = _db.Modalidades.AsNoTracking().AsQueryable();
        if (!incluirInativas) query = query.Where(m => m.Ativa);
        var itens = await query.OrderBy(m => m.Nome).Select(m => Map(m)).ToListAsync(ct);
        return Ok(itens);
    }

    [HttpPost]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<ModalidadeDto>> Criar(ModalidadeRequest req, CancellationToken ct)
    {
        var m = new Modalidade { Nome = req.Nome, Ativa = req.Ativa };
        _db.Modalidades.Add(m);
        await _db.SaveChangesAsync(ct);
        return Ok(Map(m));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<ModalidadeDto>> Atualizar(Guid id, ModalidadeRequest req, CancellationToken ct)
    {
        var m = await _db.Modalidades.FindAsync([id], ct);
        if (m is null) return NotFound();
        m.Nome = req.Nome;
        m.Ativa = req.Ativa;
        await _db.SaveChangesAsync(ct);
        return Ok(Map(m));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<IActionResult> Excluir(Guid id, CancellationToken ct)
    {
        var m = await _db.Modalidades.FindAsync([id], ct);
        if (m is null) return NotFound();

        var temCompetidores = await _db.Competidores.AnyAsync(c => c.ModalidadeId == id, ct);
        if (temCompetidores)
        {
            m.Ativa = false;
            await _db.SaveChangesAsync(ct);
            return Ok(new { mensagem = "Modalidade possui competidores; foi inativada em vez de excluída." });
        }

        _db.Modalidades.Remove(m);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}
