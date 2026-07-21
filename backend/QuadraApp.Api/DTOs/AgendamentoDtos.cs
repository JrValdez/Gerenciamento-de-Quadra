using System.ComponentModel.DataAnnotations;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.DTOs;

public record AgendamentoDto(
    Guid Id,
    Guid QuadraId,
    string QuadraNome,
    DateTime Inicio,
    DateTime Fim,
    string NomeCliente,
    string TelefoneCliente,
    string EmailCliente,
    StatusAgendamento Status,
    decimal ValorTotal,
    string? Observacoes,
    DateTime CriadoEm,
    decimal ValorDesconto,
    string? CupomCodigo);

/// <summary>Agendamento público (cliente sem login). Nome, telefone e e-mail obrigatórios.
/// Se <c>Senha</c> for informada, o usuário Cliente é criado com senha para que possa
/// logar e acompanhar a reserva.</summary>
public record AgendamentoPublicoRequest(
    [Required] Guid QuadraId,
    [Required] DateTime Inicio,
    [Required] DateTime Fim,
    [Required] string NomeCliente,
    [Required] string TelefoneCliente,
    [Required, EmailAddress] string EmailCliente,
    string? Senha = null,
    string? Observacoes = null,
    string? CupomCodigo = null);

/// <summary>Consulta pública de agendamentos por e-mail e telefone (sem login).</summary>
public record AgendamentoConsultaRequest(
    [Required, EmailAddress] string Email,
    [Required] string Telefone);

/// <summary>Cancelamento de agendamento pelo próprio cliente.</summary>
public record AgendamentoCancelarRequest(
    [Required, EmailAddress] string Email,
    [Required] string Telefone);

/// <summary>Criação por atendente/admin (pode já confirmar).</summary>
public record AgendamentoCreateRequest(
    [Required] Guid QuadraId,
    [Required] DateTime Inicio,
    [Required] DateTime Fim,
    [Required] string NomeCliente,
    [Required] string TelefoneCliente,
    [Required, EmailAddress] string EmailCliente,
    StatusAgendamento Status = StatusAgendamento.Confirmado,
    string? Observacoes = null,
    string? CupomCodigo = null);

/// <summary>Reserva de quadra feita pelo próprio professor para dar aula.
/// O valor usa o preço de aula do professor e a reserva já entra confirmada.</summary>
public record AgendamentoAulaRequest(
    [Required] Guid QuadraId,
    [Required] DateTime Inicio,
    [Required] DateTime Fim,
    string? Observacoes = null);

public record AgendamentoStatusRequest([Required] StatusAgendamento Status);

/// <summary>Faixa de horário livre para exibir disponibilidade.</summary>
public record DisponibilidadeSlot(DateTime Inicio, DateTime Fim, bool Disponivel);
