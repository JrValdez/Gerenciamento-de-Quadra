namespace QuadraApp.Api.Infra;

/// <summary>
/// Estado do usuário conferido a cada requisição para revogar tokens (usuário ativo +
/// security stamp atual). Fica em cache por poucos segundos para evitar uma ida ao banco
/// em toda chamada autenticada; as operações que invalidam a sessão (inativar, redefinir
/// senha, excluir) removem a entrada do cache para a revogação continuar imediata.
/// </summary>
public sealed record AuthUserSnapshot(bool Ativo, string SecurityStamp)
{
    /// <summary>Chave de cache do snapshot de um usuário.</summary>
    public static string Chave(string userId) => $"auth:snapshot:{userId}";
}
