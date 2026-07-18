using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Sessão de caixa (abertura → fechamento). Só um caixa aberto por vez.</summary>
public class Caixa
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public DateTime AbertoEm { get; set; } = DateTime.UtcNow;
    public DateTime? FechadoEm { get; set; }

    public decimal ValorAbertura { get; set; }

    /// <summary>Valor contado na hora do fechamento (informado pelo operador).</summary>
    public decimal? ValorFechamentoInformado { get; set; }

    public StatusCaixa Status { get; set; } = StatusCaixa.Aberto;

    public Guid AbertoPorUserId { get; set; }
    public Guid? FechadoPorUserId { get; set; }

    [MaxLength(500)]
    public string? Observacoes { get; set; }

    public ICollection<MovimentacaoCaixa> Movimentacoes { get; set; } = new List<MovimentacaoCaixa>();
}
