using System.ComponentModel.DataAnnotations;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.DTOs;

public record CupomDto(
    Guid Id,
    string Codigo,
    string? Descricao,
    TipoDesconto Tipo,
    decimal Valor,
    DateTime ValidoAte,
    bool Ativo,
    bool Valido);

public record CupomCreateRequest(
    [Required] string Codigo,
    string? Descricao,
    [Required] TipoDesconto Tipo,
    [Range(0.01, 1000000)] decimal Valor,
    [Required] DateTime ValidoAte,
    bool Ativo = true);

public record CupomUpdateRequest(
    [Required] string Codigo,
    string? Descricao,
    [Required] TipoDesconto Tipo,
    [Range(0.01, 1000000)] decimal Valor,
    [Required] DateTime ValidoAte,
    bool Ativo);
