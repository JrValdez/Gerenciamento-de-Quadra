using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Venda de produtos no balcão. Gera uma movimentação de entrada no caixa.</summary>
public class Venda
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CaixaId { get; set; }
    public Caixa? Caixa { get; set; }

    public decimal Total { get; set; }

    public FormaPagamento FormaPagamento { get; set; } = FormaPagamento.Dinheiro;

    [MaxLength(120)]
    public string? NomeCliente { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public Guid RegistradoPorUserId { get; set; }

    public ICollection<VendaItem> Itens { get; set; } = new List<VendaItem>();
}

/// <summary>Item de uma venda. Guarda snapshot de nome/preço do produto.</summary>
public class VendaItem
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid VendaId { get; set; }
    public Venda? Venda { get; set; }

    public Guid ProdutoId { get; set; }
    public Produto? Produto { get; set; }

    [MaxLength(120)]
    public string ProdutoNome { get; set; } = string.Empty;

    public int Quantidade { get; set; }
    public decimal PrecoUnitario { get; set; }
    public decimal Subtotal { get; set; }
}
