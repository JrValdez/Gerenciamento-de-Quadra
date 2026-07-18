using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>
/// Reserva de uma quadra. Pode ser criada por um cliente sem login
/// (apenas nome/telefone/e-mail) ou por um atendente/admin.
/// </summary>
public class Agendamento
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid QuadraId { get; set; }
    public Quadra? Quadra { get; set; }

    public DateTime Inicio { get; set; }
    public DateTime Fim { get; set; }

    [MaxLength(120)]
    public string NomeCliente { get; set; } = string.Empty;

    [MaxLength(30)]
    public string TelefoneCliente { get; set; } = string.Empty;

    [MaxLength(160)]
    public string EmailCliente { get; set; } = string.Empty;

    public StatusAgendamento Status { get; set; } = StatusAgendamento.Pendente;

    public decimal ValorTotal { get; set; }

    [MaxLength(500)]
    public string? Observacoes { get; set; }

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    /// <summary>Nulo quando o próprio cliente agendou (autoatendimento sem login).</summary>
    public Guid? CriadoPorUserId { get; set; }
}
