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
public class CaixaController : ControllerBase
{
    private readonly AppDbContext _db;
    private readonly CaixaService _svc;
    public CaixaController(AppDbContext db, CaixaService svc)
    {
        _db = db;
        _svc = svc;
    }

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static CaixaDto Map(Caixa c)
    {
        var (entradas, saidas, saldo) = CaixaService.Totais(c);
        return new CaixaDto(c.Id, c.AbertoEm, c.FechadoEm, c.ValorAbertura,
            c.ValorFechamentoInformado, c.Status, c.Observacoes,
            entradas, saidas, saldo);
    }

    /// <summary>Retorna o caixa aberto no momento (se houver).</summary>
    [HttpGet("atual")]
    public async Task<ActionResult<CaixaDto>> Atual(CancellationToken ct)
    {
        var caixa = await _svc.AtualAsync(ct);
        return caixa is null ? NoContent() : Ok(Map(caixa));
    }

    [HttpPost("abrir")]
    public async Task<ActionResult<CaixaDto>> Abrir(AbrirCaixaRequest req, CancellationToken ct)
    {
        var (caixa, erro, conflito) = await _svc.AbrirAsync(req, UsuarioAtual(), ct);
        if (erro is not null)
            return conflito ? Conflict(new { erro }) : BadRequest(new { erro });
        return Ok(Map(caixa!));
    }

    [HttpPost("fechar")]
    public async Task<ActionResult<CaixaDto>> Fechar(FecharCaixaRequest req, CancellationToken ct)
    {
        var (caixa, erro) = await _svc.FecharAsync(req, UsuarioAtual(), ct);
        if (erro is not null) return BadRequest(new { erro });
        return Ok(Map(caixa!));
    }

    /// <summary>Histórico de caixas (fechados e aberto).</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<CaixaDto>>> Listar(
        [FromQuery] int? page, [FromQuery] int? pageSize)
    {
        var pg = Paginacao.De(page, pageSize, padrao: 90, max: 365);
        Response.Headers["X-Total-Count"] = (await _db.Caixas.CountAsync()).ToString();

        var caixas = await _db.Caixas.Include(c => c.Movimentacoes)
            .OrderByDescending(c => c.AbertoEm)
            .Skip(pg.Skip).Take(pg.PageSize).ToListAsync();
        return Ok(caixas.Select(Map));
    }

    [HttpGet("{id:guid}/movimentacoes")]
    public async Task<ActionResult<IEnumerable<MovimentacaoDto>>> Movimentacoes(Guid id)
    {
        var itens = await _db.MovimentacoesCaixa.AsNoTracking()
            .Where(m => m.CaixaId == id)
            .OrderByDescending(m => m.CriadoEm)
            .Select(m => new MovimentacaoDto(m.Id, m.Tipo, m.Categoria, m.Valor,
                m.Descricao, m.FormaPagamento, m.CriadoEm, m.AgendamentoId, m.VendaId))
            .ToListAsync();
        return Ok(itens);
    }

    /// <summary>Lança uma movimentação manual (sangria, suprimento, entrada/saída avulsa).</summary>
    [HttpPost("movimentacoes")]
    public async Task<ActionResult<MovimentacaoDto>> LancarMovimentacao(
        MovimentacaoCreateRequest req, CancellationToken ct)
    {
        var (mov, erro) = await _svc.LancarMovimentacaoAsync(req, UsuarioAtual(), ct);
        if (erro is not null) return BadRequest(new { erro });
        return Ok(new MovimentacaoDto(mov!.Id, mov.Tipo, mov.Categoria, mov.Valor,
            mov.Descricao, mov.FormaPagamento, mov.CriadoEm, mov.AgendamentoId, mov.VendaId));
    }
}
