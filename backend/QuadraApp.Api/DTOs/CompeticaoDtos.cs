using System.ComponentModel.DataAnnotations;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.DTOs;

// ----- Modalidades -----
public record ModalidadeDto(Guid Id, string Nome, bool Ativa);

public record ModalidadeRequest(
    [Required] string Nome,
    bool Ativa = true);

// ----- Alunos (para seleção) -----
public record AlunoDto(Guid Id, string Nome, string Email, string? Telefone = null);

// ----- Competidores -----
public record MembroDto(Guid AlunoId, string AlunoNome);

public record CompetidorDto(
    Guid Id,
    Guid ModalidadeId,
    TipoCompetidor Tipo,
    string Nome,
    bool Ativo,
    IEnumerable<MembroDto> Membros);

public record CompetidorCreateRequest(
    [Required] Guid ModalidadeId,
    [Required] TipoCompetidor Tipo,
    string? Nome,
    [Required, MinLength(1)] List<Guid> AlunosIds);

public record CompetidorUpdateRequest(
    string? Nome,
    bool Ativo,
    [Required, MinLength(1)] List<Guid> AlunosIds);

// ----- Lançamentos de pontos -----
public record LancamentoRequest(
    [Required] Guid CompetidorId,
    [Required] int Pontos,
    [Required] string Motivo);

public record LancamentoDto(
    Guid Id,
    Guid CompetidorId,
    string CompetidorNome,
    int Pontos,
    string Motivo,
    DateTime Data);

// ----- Classificação -----
public record ClassificacaoItemDto(
    int Posicao,
    Guid CompetidorId,
    string Nome,
    TipoCompetidor Tipo,
    int TotalPontos,
    int QtdLancamentos,
    IEnumerable<MembroDto> Membros);
