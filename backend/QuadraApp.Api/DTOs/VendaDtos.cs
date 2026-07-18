using System.ComponentModel.DataAnnotations;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.DTOs;

public record VendaItemDto(
    Guid ProdutoId,
    string ProdutoNome,
    int Quantidade,
    decimal PrecoUnitario,
    decimal Subtotal);

public record VendaDto(
    Guid Id,
    decimal Total,
    FormaPagamento FormaPagamento,
    string? NomeCliente,
    DateTime CriadoEm,
    IEnumerable<VendaItemDto> Itens);

public record VendaItemRequest(
    [Required] Guid ProdutoId,
    [Range(1, 100000)] int Quantidade);

public record VendaCreateRequest(
    [Required, MinLength(1)] List<VendaItemRequest> Itens,
    FormaPagamento FormaPagamento = FormaPagamento.Dinheiro,
    string? NomeCliente = null);
