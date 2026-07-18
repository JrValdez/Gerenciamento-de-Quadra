using System.ComponentModel.DataAnnotations;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.DTOs;

public record CaixaDto(
    Guid Id,
    DateTime AbertoEm,
    DateTime? FechadoEm,
    decimal ValorAbertura,
    decimal? ValorFechamentoInformado,
    StatusCaixa Status,
    string? Observacoes,
    decimal TotalEntradas,
    decimal TotalSaidas,
    decimal SaldoEsperado);

public record AbrirCaixaRequest(
    [Range(0, 1000000)] decimal ValorAbertura,
    string? Observacoes = null);

public record FecharCaixaRequest(
    [Range(0, 1000000)] decimal ValorFechamentoInformado,
    string? Observacoes = null);

public record MovimentacaoDto(
    Guid Id,
    TipoMovimentacao Tipo,
    string Categoria,
    decimal Valor,
    string Descricao,
    FormaPagamento FormaPagamento,
    DateTime CriadoEm,
    Guid? AgendamentoId,
    Guid? VendaId);

/// <summary>Movimentação manual (sangria, suprimento, entrada/saída avulsa).</summary>
public record MovimentacaoCreateRequest(
    [Required] TipoMovimentacao Tipo,
    [Required] string Categoria,
    [Range(0.01, 1000000)] decimal Valor,
    [Required] string Descricao,
    FormaPagamento FormaPagamento = FormaPagamento.Dinheiro);
