using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class QuadrasController : ControllerBase
{
    private readonly AppDbContext _db;
    public QuadrasController(AppDbContext db) => _db = db;

    private static QuadraDto Map(Quadra q) =>
        new(q.Id, q.Nome, q.PrecoHora, q.HoraAbertura, q.HoraFechamento, q.Ativa, q.Observacoes);

    /// <summary>Lista quadras. Público vê apenas ativas; interno vê todas com ?incluirInativas=true.</summary>
    [HttpGet]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<QuadraDto>>> Listar(
        [FromQuery] bool incluirInativas = false, CancellationToken ct = default)
    {
        var query = _db.Quadras.AsNoTracking().AsQueryable();
        if (!incluirInativas)
            query = query.Where(q => q.Ativa);

        var itens = await query.OrderBy(q => q.Nome).Select(q => Map(q)).ToListAsync(ct);
        return Ok(itens);
    }

    [HttpGet("{id:guid}")]
    [AllowAnonymous]
    public async Task<ActionResult<QuadraDto>> Obter(Guid id, CancellationToken ct)
    {
        var q = await _db.Quadras.FindAsync([id], ct);
        return q is null ? NotFound() : Ok(Map(q));
    }

    [HttpPost]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<QuadraDto>> Criar(QuadraCreateRequest req, CancellationToken ct)
    {
        if (req.HoraFechamento <= req.HoraAbertura)
            return BadRequest(new { erro = "Hora de fechamento deve ser maior que a de abertura." });

        var q = new Quadra
        {
            Nome = req.Nome,
            PrecoHora = req.PrecoHora,
            HoraAbertura = req.HoraAbertura,
            HoraFechamento = req.HoraFechamento,
            Ativa = req.Ativa,
            Observacoes = req.Observacoes,
        };
        _db.Quadras.Add(q);
        await _db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(Obter), new { id = q.Id }, Map(q));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<QuadraDto>> Atualizar(Guid id, QuadraUpdateRequest req, CancellationToken ct)
    {
        if (req.HoraFechamento <= req.HoraAbertura)
            return BadRequest(new { erro = "Hora de fechamento deve ser maior que a de abertura." });

        var q = await _db.Quadras.FindAsync([id], ct);
        if (q is null) return NotFound();

        q.Nome = req.Nome;
        q.PrecoHora = req.PrecoHora;
        q.HoraAbertura = req.HoraAbertura;
        q.HoraFechamento = req.HoraFechamento;
        q.Ativa = req.Ativa;
        q.Observacoes = req.Observacoes;
        await _db.SaveChangesAsync(ct);
        return Ok(Map(q));
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Excluir(Guid id, CancellationToken ct)
    {
        var q = await _db.Quadras.FindAsync([id], ct);
        if (q is null) return NotFound();

        // Se já houver agendamentos, apenas inativa (preserva histórico).
        var temAgendamentos = await _db.Agendamentos.AnyAsync(a => a.QuadraId == id, ct);
        if (temAgendamentos)
        {
            q.Ativa = false;
            await _db.SaveChangesAsync(ct);
            return Ok(new { mensagem = "Quadra possui agendamentos; foi inativada em vez de excluída." });
        }

        _db.Quadras.Remove(q);
        await _db.SaveChangesAsync(ct);
        return NoContent();
    }
}
