using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Data;

/// <summary>
/// Aplica as migrações, garante as roles e cria o administrador inicial a partir de
/// configuração (App:AdminEmail / App:AdminPassword). A senha nunca fica no código
/// nem é registrada em log — é apenas repassada ao Identity, que a armazena com hash.
/// Também semeia dados neutros de exemplo (quadras, produtos, modalidades) num banco vazio.
/// </summary>
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var sp = scope.ServiceProvider;
        var db = sp.GetRequiredService<AppDbContext>();
        var userManager = sp.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = sp.GetRequiredService<RoleManager<IdentityRole<Guid>>>();
        var config = sp.GetRequiredService<IConfiguration>();
        var logger = sp.GetRequiredService<ILoggerFactory>().CreateLogger("DbSeeder");

        await db.Database.MigrateAsync();

        foreach (var papel in Roles.All)
        {
            if (!await roleManager.RoleExistsAsync(papel))
                await roleManager.CreateAsync(new IdentityRole<Guid>(papel));
        }

        // ----- Administrador inicial -----
        // Credenciais vêm da configuração (variáveis de ambiente App__AdminEmail /
        // App__AdminPassword), nunca do código. O Identity guarda a senha com hash.
        var adminEmail = config["App:AdminEmail"];
        var adminSenha = config["App:AdminPassword"];
        if (!string.IsNullOrWhiteSpace(adminEmail) && !string.IsNullOrWhiteSpace(adminSenha))
        {
            if (await userManager.FindByEmailAsync(adminEmail) is null)
            {
                var admin = new ApplicationUser
                {
                    UserName = adminEmail,
                    Email = adminEmail,
                    EmailConfirmed = true,
                    NomeCompleto = "Administrador",
                };
                var resultado = await userManager.CreateAsync(admin, adminSenha);
                if (resultado.Succeeded)
                {
                    await userManager.AddToRoleAsync(admin, Roles.Admin);
                    logger.LogInformation("Administrador inicial criado ({Email}).", adminEmail);
                }
                else
                {
                    // Nunca logamos a senha — apenas o motivo da recusa (política/duplicidade).
                    logger.LogError("Falha ao criar administrador inicial: {Erros}",
                        string.Join("; ", resultado.Errors.Select(e => e.Description)));
                }
            }
        }
        else
        {
            logger.LogWarning(
                "App:AdminEmail/App:AdminPassword não configurados — nenhum administrador foi criado.");
        }

        // ----- Dados de exemplo (não são usuários) — apenas em banco vazio -----
        if (!await db.Quadras.AnyAsync())
        {
            db.Quadras.AddRange(
                new Quadra { Nome = "Quadra 1 - Society", PrecoHora = 80m },
                new Quadra { Nome = "Quadra 2 - Beach Tennis", PrecoHora = 60m },
                new Quadra { Nome = "Quadra 3 - Vôlei", PrecoHora = 50m });
        }

        if (!await db.Produtos.AnyAsync())
        {
            db.Produtos.AddRange(
                new Produto { Nome = "Água Mineral 500ml", Categoria = "Bebida", Preco = 4m, EstoqueQuantidade = 100 },
                new Produto { Nome = "Refrigerante Lata", Categoria = "Bebida", Preco = 6m, EstoqueQuantidade = 80 },
                new Produto { Nome = "Isotônico", Categoria = "Bebida", Preco = 8m, EstoqueQuantidade = 40 },
                new Produto { Nome = "Barra de Cereal", Categoria = "Lanche", Preco = 5m, EstoqueQuantidade = 50 });
        }

        if (!await db.Modalidades.AnyAsync())
        {
            db.Modalidades.AddRange(
                new Modalidade { Nome = "Beach Tennis" },
                new Modalidade { Nome = "Vôlei" },
                new Modalidade { Nome = "Futvôlei" });
        }

        await db.SaveChangesAsync();
    }
}
