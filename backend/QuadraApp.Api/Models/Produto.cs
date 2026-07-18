using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Produto vendável no balcão (água, refrigerante, etc.).</summary>
public class Produto
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [MaxLength(120)]
    public string Nome { get; set; } = string.Empty;

    [MaxLength(300)]
    public string? Descricao { get; set; }

    /// <summary>Categoria livre: Bebida, Lanche, Acessório, etc.</summary>
    [MaxLength(60)]
    public string Categoria { get; set; } = "Geral";

    public decimal Preco { get; set; }

    public int EstoqueQuantidade { get; set; }

    public bool Ativo { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
