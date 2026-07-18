using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Cupom de desconto criado pela equipe (Admin/Atendente), com prazo de validade.</summary>
public class Cupom
{
    public Guid Id { get; set; } = Guid.NewGuid();

    /// <summary>Código digitado pelo cliente. Único, guardado em maiúsculas.</summary>
    [MaxLength(40)]
    public string Codigo { get; set; } = string.Empty;

    [MaxLength(200)]
    public string? Descricao { get; set; }

    public TipoDesconto Tipo { get; set; } = TipoDesconto.Percentual;

    /// <summary>Percentual (0-100) ou valor fixo em reais, conforme <see cref="Tipo"/>.</summary>
    public decimal Valor { get; set; }

    /// <summary>Data/hora até quando o cupom é válido (prazo de validade).</summary>
    public DateTime ValidoAte { get; set; }

    public bool Ativo { get; set; } = true;

    public Guid CriadoPorUserId { get; set; }
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
