using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.DTOs;

public record BloqueioDto(
    Guid Id,
    Guid QuadraId,
    string QuadraNome,
    DateTime Inicio,
    DateTime Fim,
    string? Motivo);

public record BloqueioCreateRequest(
    [Required] Guid QuadraId,
    [Required] DateTime Inicio,
    [Required] DateTime Fim,
    string? Motivo = null);
