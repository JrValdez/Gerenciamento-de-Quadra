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

/// <summary>Agendamento público (cliente sem login). Nome, telefone e e-mail obrigatórios.</summary>
public record AgendamentoPublicoRequest(
    [Required] Guid QuadraId,
    [Required] DateTime Inicio,
    [Required] DateTime Fim,
    [Required] string NomeCliente,
    [Required] string TelefoneCliente,
    [Required, EmailAddress] string EmailCliente,
    string? Observacoes = null,
    string? CupomCodigo = null);

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

public record AgendamentoStatusRequest([Required] StatusAgendamento Status);

/// <summary>Faixa de horário livre para exibir disponibilidade.</summary>
public record DisponibilidadeSlot(DateTime Inicio, DateTime Fim, bool Disponivel);
