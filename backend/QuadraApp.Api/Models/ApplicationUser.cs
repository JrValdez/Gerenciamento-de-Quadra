using Microsoft.AspNetCore.Identity;

namespace QuadraApp.Api.Models;

/// <summary>Usuário do sistema (Admin, Atendente ou Cliente cadastrado).</summary>
public class ApplicationUser : IdentityUser<Guid>
{
    public string NomeCompleto { get; set; } = string.Empty;
    public bool Ativo { get; set; } = true;
    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;
}
