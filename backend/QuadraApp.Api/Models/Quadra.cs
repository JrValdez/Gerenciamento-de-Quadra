using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Uma quadra que pode ser reservada.</summary>
public class Quadra
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [MaxLength(120)]
    public string Nome { get; set; } = string.Empty;

    public decimal PrecoHora { get; set; }

    /// <summary>Hora de abertura (0-23). Padrão 8h.</summary>
    public int HoraAbertura { get; set; } = 8;

    /// <summary>Hora de fechamento (1-24). Padrão 22h.</summary>
    public int HoraFechamento { get; set; } = 22;

    public bool Ativa { get; set; } = true;

    [MaxLength(500)]
    public string? Observacoes { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public ICollection<Agendamento> Agendamentos { get; set; } = new List<Agendamento>();
}
