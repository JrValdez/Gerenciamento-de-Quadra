using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.DTOs;

public record ProdutoDto(
    Guid Id,
    string Nome,
    string? Descricao,
    string Categoria,
    decimal Preco,
    int EstoqueQuantidade,
    bool Ativo);

public record ProdutoCreateRequest(
    [Required] string Nome,
    string? Descricao,
    [Required] string Categoria,
    [Range(0, 100000)] decimal Preco,
    [Range(0, 1000000)] int EstoqueQuantidade,
    bool Ativo = true);

public record ProdutoUpdateRequest(
    [Required] string Nome,
    string? Descricao,
    [Required] string Categoria,
    [Range(0, 100000)] decimal Preco,
    [Range(0, 1000000)] int EstoqueQuantidade,
    bool Ativo);
