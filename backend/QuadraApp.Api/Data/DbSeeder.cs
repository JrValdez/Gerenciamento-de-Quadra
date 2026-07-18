using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Data;

/// <summary>Cria roles, um admin padrão e dados de exemplo na primeira execução.</summary>
public static class DbSeeder
{
    public static async Task SeedAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var userManager = scope.ServiceProvider.GetRequiredService<UserManager<ApplicationUser>>();
        var roleManager = scope.ServiceProvider.GetRequiredService<RoleManager<IdentityRole<Guid>>>();

        await db.Database.MigrateAsync();

        foreach (var papel in Roles.All)
        {
            if (!await roleManager.RoleExistsAsync(papel))
                await roleManager.CreateAsync(new IdentityRole<Guid>(papel));
        }

        const string adminEmail = "admin@quadra.local";
        if (await userManager.FindByEmailAsync(adminEmail) is null)
        {
            var admin = new ApplicationUser
            {
                UserName = adminEmail,
                Email = adminEmail,
                EmailConfirmed = true,
                NomeCompleto = "Administrador",
            };
            await userManager.CreateAsync(admin, "Admin@123");
            await userManager.AddToRoleAsync(admin, Roles.Admin);
        }

        const string atendenteEmail = "atendente@quadra.local";
        if (await userManager.FindByEmailAsync(atendenteEmail) is null)
        {
            var atendente = new ApplicationUser
            {
                UserName = atendenteEmail,
                Email = atendenteEmail,
                EmailConfirmed = true,
                NomeCompleto = "Atendente Padrão",
            };
            await userManager.CreateAsync(atendente, "Atendente@123");
            await userManager.AddToRoleAsync(atendente, Roles.Atendente);
        }

        const string professorEmail = "professor@quadra.local";
        if (await userManager.FindByEmailAsync(professorEmail) is null)
        {
            var professor = new ApplicationUser
            {
                UserName = professorEmail,
                Email = professorEmail,
                EmailConfirmed = true,
                NomeCompleto = "Professor Padrão",
            };
            await userManager.CreateAsync(professor, "Professor@123");
            await userManager.AddToRoleAsync(professor, Roles.Professor);
        }

        // Alunos de exemplo
        var alunosSeed = new[]
        {
            ("aluno1@quadra.local", "Ana Souza"),
            ("aluno2@quadra.local", "Bruno Lima"),
            ("aluno3@quadra.local", "Carla Dias"),
            ("aluno4@quadra.local", "Diego Alves"),
        };
        foreach (var (email, nome) in alunosSeed)
        {
            if (await userManager.FindByEmailAsync(email) is null)
            {
                var aluno = new ApplicationUser
                {
                    UserName = email,
                    Email = email,
                    EmailConfirmed = true,
                    NomeCompleto = nome,
                };
                await userManager.CreateAsync(aluno, "Aluno@123");
                await userManager.AddToRoleAsync(aluno, Roles.Aluno);
            }
        }

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

        // ----- Competição -----
        if (!await db.Modalidades.AnyAsync())
        {
            var beach = new Modalidade { Nome = "Beach Tennis" };
            var volei = new Modalidade { Nome = "Vôlei" };
            var futvolei = new Modalidade { Nome = "Futvôlei" };
            db.Modalidades.AddRange(beach, volei, futvolei);

            var alunos = (await userManager.GetUsersInRoleAsync(Roles.Aluno))
                .OrderBy(a => a.NomeCompleto).ToList();

            if (alunos.Count >= 4)
            {
                // Beach Tennis: 3 competidores individuais com pontos
                var indiv = new List<(ApplicationUser aluno, int pts)>
                {
                    (alunos[0], 30),
                    (alunos[1], 24),
                    (alunos[2], 18),
                };
                foreach (var (aluno, pts) in indiv)
                {
                    var comp = new Competidor
                    {
                        Modalidade = beach,
                        Tipo = TipoCompetidor.Individual,
                        Nome = aluno.NomeCompleto,
                        Membros = { new CompetidorMembro { AlunoId = aluno.Id, AlunoNome = aluno.NomeCompleto } },
                    };
                    comp.Lancamentos.Add(new LancamentoPonto
                    {
                        ModalidadeId = beach.Id,
                        Pontos = pts,
                        Motivo = "Etapa de abertura",
                    });
                    db.Competidores.Add(comp);
                }

                // Vôlei: 2 equipes com pontos
                var equipeA = new Competidor
                {
                    Modalidade = volei,
                    Tipo = TipoCompetidor.Equipe,
                    Nome = "Time Fênix",
                    Membros =
                    {
                        new CompetidorMembro { AlunoId = alunos[0].Id, AlunoNome = alunos[0].NomeCompleto },
                        new CompetidorMembro { AlunoId = alunos[1].Id, AlunoNome = alunos[1].NomeCompleto },
                    },
                };
                equipeA.Lancamentos.Add(new LancamentoPonto { ModalidadeId = volei.Id, Pontos = 21, Motivo = "Torneio interno" });

                var equipeB = new Competidor
                {
                    Modalidade = volei,
                    Tipo = TipoCompetidor.Equipe,
                    Nome = "Time Trovão",
                    Membros =
                    {
                        new CompetidorMembro { AlunoId = alunos[2].Id, AlunoNome = alunos[2].NomeCompleto },
                        new CompetidorMembro { AlunoId = alunos[3].Id, AlunoNome = alunos[3].NomeCompleto },
                    },
                };
                equipeB.Lancamentos.Add(new LancamentoPonto { ModalidadeId = volei.Id, Pontos = 15, Motivo = "Torneio interno" });

                db.Competidores.AddRange(equipeA, equipeB);
            }
        }

        await db.SaveChangesAsync();
    }
}
