using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Entrada ou saída de dinheiro dentro de uma sessão de caixa.</summary>
public class MovimentacaoCaixa
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CaixaId { get; set; }
    public Caixa? Caixa { get; set; }

    public TipoMovimentacao Tipo { get; set; }

    /// <summary>Origem: Agendamento, Venda, Sangria, Suprimento, Outro.</summary>
    [MaxLength(40)]
    public string Categoria { get; set; } = "Outro";

    public decimal Valor { get; set; }

    [MaxLength(300)]
    public string Descricao { get; set; } = string.Empty;

    public FormaPagamento FormaPagamento { get; set; } = FormaPagamento.Dinheiro;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public Guid? AgendamentoId { get; set; }
    public Guid? VendaId { get; set; }

    public Guid RegistradoPorUserId { get; set; }
}
