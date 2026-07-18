using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>
/// Período em que uma quadra fica indisponível para reserva
/// (manutenção, evento, folga...). Pode ser uma faixa de horas ou o dia inteiro.
/// </summary>
public class Bloqueio
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid QuadraId { get; set; }
    public Quadra? Quadra { get; set; }

    public DateTime Inicio { get; set; }
    public DateTime Fim { get; set; }

    [MaxLength(200)]
    public string? Motivo { get; set; }

    public Guid CriadoPorUserId { get; set; }
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
