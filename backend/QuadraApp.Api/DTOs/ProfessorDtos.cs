using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.DTOs;

/// <summary>Professor com o preço por hora da aula (gestão por Admin/Atendente).</summary>
public record ProfessorDto(
    Guid Id,
    string NomeCompleto,
    string Email,
    decimal PrecoAula,
    bool Ativo);

/// <summary>Define o preço por hora da aula de um professor.</summary>
public record PrecoAulaRequest(
    [Range(0, 100000)] decimal PrecoAula);

/// <summary>Criação de um aluno pelo professor. O papel é sempre Aluno.</summary>
public record CriarAlunoRequest(
    [Required] string NomeCompleto,
    [Required, EmailAddress] string Email,
    [Required, Phone] string Telefone,
    [Required, MinLength(6)] string Senha);
