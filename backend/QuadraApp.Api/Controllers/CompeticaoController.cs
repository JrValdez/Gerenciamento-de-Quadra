using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CompeticaoController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly UserManager<ApplicationUser> _userManager;

    public CompeticaoController(AppDbContext db, UserManager<ApplicationUser> userManager)
    {
        _db = db;
        _userManager = userManager;
    }

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static CompetidorDto MapCompetidor(Competidor c) =>
        new(c.Id, c.ModalidadeId, c.Tipo, c.Nome, c.Ativo,
            c.Membros.Select(m => new MembroDto(m.AlunoId, m.AlunoNome)));

    // ----- Alunos (para montar competidores) -----
    [HttpGet("alunos")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<IEnumerable<AlunoDto>>> Alunos()
    {
        var alunos = await _userManager.GetUsersInRoleAsync(Roles.Aluno);
        return Ok(alunos
            .Where(a => a.Ativo)
            .OrderBy(a => a.NomeCompleto)
            .Select(a => new AlunoDto(a.Id, a.NomeCompleto, a.Email!)));
    }

    // ----- Competidores -----
    [HttpGet("competidores")]
    public async Task<ActionResult<IEnumerable<CompetidorDto>>> Competidores([FromQuery] Guid modalidadeId)
    {
        var itens = await _db.Competidores.AsNoTracking()
            .Include(c => c.Membros)
            .Where(c => c.ModalidadeId == modalidadeId)
            .OrderBy(c => c.Nome)
            .ToListAsync();
        return Ok(itens.Select(MapCompetidor));
    }

    [HttpPost("competidores")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<CompetidorDto>> CriarCompetidor(CompetidorCreateRequest req)
    {
        var modalidade = await _db.Modalidades.FindAsync(req.ModalidadeId);
        if (modalidade is null) return BadRequest(new { erro = "Modalidade inexistente." });

        if (req.Tipo == TipoCompetidor.Individual && req.AlunosIds.Count != 1)
            return BadRequest(new { erro = "Competidor individual deve ter exatamente 1 aluno." });

        var membros = await MontarMembros(req.AlunosIds);
        if (membros is null) return BadRequest(new { erro = "Um ou mais alunos são inválidos." });

        var nome = string.IsNullOrWhiteSpace(req.Nome)
            ? (req.Tipo == TipoCompetidor.Individual ? membros[0].AlunoNome : "Equipe")
            : req.Nome.Trim();

        var competidor = new Competidor
        {
            ModalidadeId = req.ModalidadeId,
            Tipo = req.Tipo,
            Nome = nome,
            Membros = membros,
        };
        _db.Competidores.Add(competidor);
        await _db.SaveChangesAsync();
        return Ok(MapCompetidor(competidor));
    }

    [HttpPut("competidores/{id:guid}")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<CompetidorDto>> AtualizarCompetidor(Guid id, CompetidorUpdateRequest req)
    {
        var competidor = await _db.Competidores.Include(c => c.Membros)
            .FirstOrDefaultAsync(c => c.Id == id);
        if (competidor is null) return NotFound();

        if (competidor.Tipo == TipoCompetidor.Individual && req.AlunosIds.Count != 1)
            return BadRequest(new { erro = "Competidor individual deve ter exatamente 1 aluno." });

        var membros = await MontarMembros(req.AlunosIds);
        if (membros is null) return BadRequest(new { erro = "Um ou mais alunos são inválidos." });

        _db.CompetidorMembros.RemoveRange(competidor.Membros);
        competidor.Membros = membros;
        competidor.Ativo = req.Ativo;
        competidor.Nome = string.IsNullOrWhiteSpace(req.Nome)
            ? (competidor.Tipo == TipoCompetidor.Individual ? membros[0].AlunoNome : competidor.Nome)
            : req.Nome.Trim();
        await _db.SaveChangesAsync();
        return Ok(MapCompetidor(competidor));
    }

    [HttpDelete("competidores/{id:guid}")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<IActionResult> ExcluirCompetidor(Guid id)
    {
        var competidor = await _db.Competidores.FindAsync(id);
        if (competidor is null) return NotFound();
        _db.Competidores.Remove(competidor); // cascade remove membros e lançamentos
        await _db.SaveChangesAsync();
        return NoContent();
    }

    private async Task<List<CompetidorMembro>?> MontarMembros(List<Guid> alunosIds)
    {
        var lista = new List<CompetidorMembro>();
        foreach (var alunoId in alunosIds.Distinct())
        {
            var aluno = await _userManager.FindByIdAsync(alunoId.ToString());
            if (aluno is null) return null;
            lista.Add(new CompetidorMembro
            {
                AlunoId = aluno.Id,
                AlunoNome = aluno.NomeCompleto,
            });
        }
        return lista;
    }

    // ----- Lançamentos de pontos -----
    [HttpPost("lancamentos")]
    [Authorize(Roles = Roles.GestoresCompeticao)]
    public async Task<ActionResult<LancamentoDto>> LancarPontos(LancamentoRequest req)
    {
        var competidor = await _db.Competidores.FindAsync(req.CompetidorId);
        if (competidor is null) return BadRequest(new { erro = "Competidor inexistente." });

        var lanc = new LancamentoPonto
        {
            CompetidorId = competidor.Id,
            ModalidadeId = competidor.ModalidadeId,
            Pontos = req.Pontos,
            Motivo = req.Motivo,
            RegistradoPorUserId = UsuarioAtual(),
        };
        _db.LancamentosPonto.Add(lanc);
        await _db.SaveChangesAsync();
        return Ok(new LancamentoDto(lanc.Id, competidor.Id, competidor.Nome, lanc.Pontos, lanc.Motivo, lanc.Data));
    }

    [HttpGet("lancamentos")]
    public async Task<ActionResult<IEnumerable<LancamentoDto>>> Lancamentos(
        [FromQuery] Guid modalidadeId, [FromQuery] Guid? competidorId)
    {
        var query = _db.LancamentosPonto.AsNoTracking()
            .Include(l => l.Competidor)
            .Where(l => l.ModalidadeId == modalidadeId);
        if (competidorId is not null) query = query.Where(l => l.CompetidorId == competidorId);

        var itens = await query.OrderByDescending(l => l.Data).Take(200).ToListAsync();
        return Ok(itens.Select(l =>
            new LancamentoDto(l.Id, l.CompetidorId, l.Competidor!.Nome, l.Pontos, l.Motivo, l.Data)));
    }

    // ----- Classificação (pontos corridos) — pública -----
    [HttpGet("classificacao")]
    [AllowAnonymous]
    public async Task<ActionResult<IEnumerable<ClassificacaoItemDto>>> Classificacao(
        [FromQuery] Guid modalidadeId, [FromQuery] TipoCompetidor? tipo)
    {
        // Carrega TODOS os competidores ativos da modalidade (para cruzar times x individuais).
        var todos = await _db.Competidores.AsNoTracking()
            .Include(c => c.Membros)
            .Include(c => c.Lancamentos)
            .Where(c => c.ModalidadeId == modalidadeId && c.Ativo)
            .ToListAsync();

        // Resumo de cada time: alunos integrantes, total de pontos e qtd de lançamentos.
        var times = todos
            .Where(c => c.Tipo == TipoCompetidor.Equipe)
            .Select(t => new
            {
                Alunos = t.Membros.Select(m => m.AlunoId).ToHashSet(),
                Total = t.Lancamentos.Sum(l => l.Pontos),
                Qtd = t.Lancamentos.Count,
            })
            .ToList();

        var ordenado = todos
            .Select(c =>
            {
                var total = c.Lancamentos.Sum(l => l.Pontos);
                var qtd = c.Lancamentos.Count;

                // Pontos de time contam também para o ranking individual dos integrantes.
                if (c.Tipo == TipoCompetidor.Individual)
                {
                    var alunoId = c.Membros.FirstOrDefault()?.AlunoId;
                    if (alunoId is Guid aid)
                    {
                        foreach (var time in times.Where(t => t.Alunos.Contains(aid)))
                        {
                            total += time.Total;
                            qtd += time.Qtd;
                        }
                    }
                }

                return new { Competidor = c, Total = total, Qtd = qtd };
            })
            .Where(x => tipo == null || x.Competidor.Tipo == tipo)
            .OrderByDescending(x => x.Total)
            .ThenByDescending(x => x.Qtd)
            .ThenBy(x => x.Competidor.Nome)
            .ToList();

        var classificacao = ordenado.Select((x, i) => new ClassificacaoItemDto(
            i + 1,
            x.Competidor.Id,
            x.Competidor.Nome,
            x.Competidor.Tipo,
            x.Total,
            x.Qtd,
            x.Competidor.Membros.Select(m => new MembroDto(m.AlunoId, m.AlunoNome))));

        return Ok(classificacao);
    }
}
