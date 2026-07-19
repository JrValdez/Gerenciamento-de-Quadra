using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
public class CaixaController : ControllerBase
{
    private readonly AppDbContext _db;
    public CaixaController(AppDbContext db) => _db = db;

    private Guid UsuarioAtual() =>
        Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    private static CaixaDto Map(Caixa c)
    {
        var entradas = c.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Entrada).Sum(m => m.Valor);
        var saidas = c.Movimentacoes.Where(m => m.Tipo == TipoMovimentacao.Saida).Sum(m => m.Valor);
        return new CaixaDto(c.Id, c.AbertoEm, c.FechadoEm, c.ValorAbertura,
            c.ValorFechamentoInformado, c.Status, c.Observacoes,
            entradas, saidas, c.ValorAbertura + entradas - saidas);
    }

    /// <summary>Retorna o caixa aberto no momento (se houver).</summary>
    [HttpGet("atual")]
    public async Task<ActionResult<CaixaDto>> Atual()
    {
        var caixa = await _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto);
        return caixa is null ? NoContent() : Ok(Map(caixa));
    }

    [HttpPost("abrir")]
    public async Task<ActionResult<CaixaDto>> Abrir(AbrirCaixaRequest req)
    {
        // Checagem rápida para a UX; o índice único parcial (só um caixa Aberto) é a
        // garantia real caso duas aberturas cheguem ao mesmo tempo.
        if (await _db.Caixas.AnyAsync(c => c.Status == StatusCaixa.Aberto))
            return Conflict(new { erro = "Já existe um caixa aberto." });

        var caixa = new Caixa
        {
            ValorAbertura = req.ValorAbertura,
            Observacoes = req.Observacoes,
            AbertoPorUserId = UsuarioAtual(),
            Status = StatusCaixa.Aberto,
        };
        _db.Caixas.Add(caixa);
        try
        {
            await _db.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (PgErros.EhViolacaoUnica(ex))
        {
            return Conflict(new { erro = "Já existe um caixa aberto." });
        }
        return Ok(Map(caixa));
    }

    [HttpPost("fechar")]
    public async Task<ActionResult<CaixaDto>> Fechar(FecharCaixaRequest req)
    {
        var caixa = await _db.Caixas.Include(c => c.Movimentacoes)
            .FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto);
        if (caixa is null) return BadRequest(new { erro = "Não há caixa aberto." });

        caixa.Status = StatusCaixa.Fechado;
        caixa.FechadoEm = DateTime.UtcNow;
        caixa.FechadoPorUserId = UsuarioAtual();
        caixa.ValorFechamentoInformado = req.ValorFechamentoInformado;
        if (req.Observacoes is not null) caixa.Observacoes = req.Observacoes;
        await _db.SaveChangesAsync();
        return Ok(Map(caixa));
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
    public async Task<ActionResult<MovimentacaoDto>> LancarMovimentacao(MovimentacaoCreateRequest req)
    {
        var caixa = await _db.Caixas.FirstOrDefaultAsync(c => c.Status == StatusCaixa.Aberto);
        if (caixa is null) return BadRequest(new { erro = "Não há caixa aberto." });

        var mov = new MovimentacaoCaixa
        {
            CaixaId = caixa.Id,
            Tipo = req.Tipo,
            Categoria = req.Categoria,
            Valor = req.Valor,
            Descricao = req.Descricao,
            FormaPagamento = req.FormaPagamento,
            RegistradoPorUserId = UsuarioAtual(),
        };
        _db.MovimentacoesCaixa.Add(mov);
        await _db.SaveChangesAsync();
        return Ok(new MovimentacaoDto(mov.Id, mov.Tipo, mov.Categoria, mov.Valor,
            mov.Descricao, mov.FormaPagamento, mov.CriadoEm, mov.AgendamentoId, mov.VendaId));
    }
}
