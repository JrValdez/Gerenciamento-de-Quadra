using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.DTOs;

public record QuadraDto(
    Guid Id,
    string Nome,
    decimal PrecoHora,
    int HoraAbertura,
    int HoraFechamento,
    bool Ativa,
    string? Observacoes);

public record QuadraCreateRequest(
    [Required] string Nome,
    [Range(0, 100000)] decimal PrecoHora,
    [Range(0, 23)] int HoraAbertura = 8,
    [Range(1, 24)] int HoraFechamento = 22,
    bool Ativa = true,
    string? Observacoes = null);

public record QuadraUpdateRequest(
    [Required] string Nome,
    [Range(0, 100000)] decimal PrecoHora,
    [Range(0, 23)] int HoraAbertura,
    [Range(1, 24)] int HoraFechamento,
    bool Ativa,
    string? Observacoes);
