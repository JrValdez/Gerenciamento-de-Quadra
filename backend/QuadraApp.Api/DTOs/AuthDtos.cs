using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.DTOs;

public record LoginRequest(
    [Required, EmailAddress] string Email,
    [Required] string Senha);

public record RegisterRequest(
    [Required] string NomeCompleto,
    [Required, EmailAddress] string Email,
    [Required, MinLength(6)] string Senha,
    [Required] string Papel); // Admin | Atendente | Cliente

public record AuthResponse(
    string Token,
    DateTime ExpiraEm,
    UsuarioDto Usuario);

public record UsuarioDto(
    Guid Id,
    string NomeCompleto,
    string Email,
    IEnumerable<string> Papeis,
    bool Ativo,
    string? Telefone = null);

public record AtivoRequest([Required] bool Ativo);

/// <summary>Edição de dados básicos do usuário por Admin/Atendente.</summary>
public record EditarUsuarioRequest(
    [Required] string NomeCompleto,
    [Required, EmailAddress] string Email,
    [Phone] string? Telefone = null);

/// <summary>Alteração do papel (classificação) do usuário.</summary>
public record PapelRequest([Required] string Papel);
