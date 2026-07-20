using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;
using QuadraApp.Api.Services;
using Xunit;

namespace QuadraApp.Api.Tests;

/// <summary>
/// Testes de integração das garantias que só existem no banco real (PostgreSQL) e que
/// antes não tinham cobertura: a constraint de exclusão anti-overbooking, o índice único
/// de "um caixa aberto por vez" e a baixa de estoque atômica da venda.
///
/// Exigem um Postgres apontado por ConnectionStrings__Default (variável de ambiente).
/// Sem ele, os testes são PULADOS (não falham) — assim o `dotnet test` comum continua
/// verde. Para rodá-los, suba um Postgres e exporte a connection string.
/// </summary>
public class IntegracaoBancoTests : IAsyncLifetime
{
    private readonly string? _conn =
        Environment.GetEnvironmentVariable("ConnectionStrings__Default");

    private AppDbContext NovoContexto()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseNpgsql(_conn)
            .Options;
        return new AppDbContext(options);
    }

    /// <summary>Aplica o schema e zera as tabelas exercitadas antes de cada teste.</summary>
    public async Task InitializeAsync()
    {
        if (string.IsNullOrWhiteSpace(_conn)) return;
        await using var db = NovoContexto();
        await db.Database.MigrateAsync();
        await db.Database.ExecuteSqlRawAsync(
            @"TRUNCATE ""Agendamentos"", ""MovimentacoesCaixa"", ""VendaItens"", ""Vendas"",
                       ""Caixas"", ""Produtos"", ""Quadras"" RESTART IDENTITY CASCADE;");
    }

    public Task DisposeAsync() => Task.CompletedTask;

    private void PrecisaDeBanco() =>
        Skip.If(string.IsNullOrWhiteSpace(_conn),
            "Defina ConnectionStrings__Default apontando para um PostgreSQL para rodar os testes de integração.");

    private static readonly DateTime BaseUtc = new(2030, 1, 1, 10, 0, 0, DateTimeKind.Utc);

    private static Agendamento Reserva(Guid quadraId, DateTime inicio, DateTime fim, StatusAgendamento status) =>
        new()
        {
            QuadraId = quadraId,
            Inicio = inicio,
            Fim = fim,
            Status = status,
            NomeCliente = "Cliente",
            TelefoneCliente = "11999999999",
            EmailCliente = "cliente@exemplo.com",
            ValorTotal = 50m,
        };

    // ----- Constraint de exclusão (anti-overbooking) -----

    [SkippableFact]
    public async Task Reservas_sobrepostas_na_mesma_quadra_sao_barradas_pelo_banco()
    {
        PrecisaDeBanco();
        await using var db = NovoContexto();

        var quadra = new Quadra { Nome = "Quadra 1", PrecoHora = 50m };
        db.Quadras.Add(quadra);
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc, BaseUtc.AddHours(1), StatusAgendamento.Confirmado));
        await db.SaveChangesAsync();

        // 10:30–11:30 cruza com a 10:00–11:00 já existente.
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc.AddMinutes(30), BaseUtc.AddMinutes(90), StatusAgendamento.Pendente));
        var ex = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
        Assert.True(PgErros.EhOverlap(ex));
    }

    [SkippableFact]
    public async Task Reserva_encostada_sem_sobreposicao_e_permitida()
    {
        PrecisaDeBanco();
        await using var db = NovoContexto();

        var quadra = new Quadra { Nome = "Quadra 1", PrecoHora = 50m };
        db.Quadras.Add(quadra);
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc, BaseUtc.AddHours(1), StatusAgendamento.Confirmado));
        // 11:00–12:00 começa exatamente quando a anterior termina: intervalos [ ) não colidem.
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc.AddHours(1), BaseUtc.AddHours(2), StatusAgendamento.Confirmado));

        await db.SaveChangesAsync(); // não deve lançar
        Assert.Equal(2, await db.Agendamentos.CountAsync());
    }

    [SkippableFact]
    public async Task Reserva_cancelada_nao_ocupa_horario()
    {
        PrecisaDeBanco();
        await using var db = NovoContexto();

        var quadra = new Quadra { Nome = "Quadra 1", PrecoHora = 50m };
        db.Quadras.Add(quadra);
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc, BaseUtc.AddHours(1), StatusAgendamento.Cancelado));
        // Mesmo horário, mas a anterior está Cancelada (fora da constraint): deve passar.
        db.Agendamentos.Add(Reserva(quadra.Id, BaseUtc, BaseUtc.AddHours(1), StatusAgendamento.Confirmado));

        await db.SaveChangesAsync();
        Assert.Equal(2, await db.Agendamentos.CountAsync());
    }

    // ----- Um único caixa aberto por vez -----

    [SkippableFact]
    public async Task Nao_permite_dois_caixas_abertos()
    {
        PrecisaDeBanco();
        await using var db = NovoContexto();

        db.Caixas.Add(new Caixa { ValorAbertura = 100m, Status = StatusCaixa.Aberto });
        await db.SaveChangesAsync();

        db.Caixas.Add(new Caixa { ValorAbertura = 50m, Status = StatusCaixa.Aberto });
        var ex = await Assert.ThrowsAsync<DbUpdateException>(() => db.SaveChangesAsync());
        Assert.True(PgErros.EhViolacaoUnica(ex));
    }

    [SkippableFact]
    public async Task Varios_caixas_fechados_convivem_com_um_aberto()
    {
        PrecisaDeBanco();
        await using var db = NovoContexto();

        db.Caixas.Add(new Caixa { ValorAbertura = 10m, Status = StatusCaixa.Fechado, FechadoEm = BaseUtc });
        db.Caixas.Add(new Caixa { ValorAbertura = 20m, Status = StatusCaixa.Fechado, FechadoEm = BaseUtc });
        db.Caixas.Add(new Caixa { ValorAbertura = 30m, Status = StatusCaixa.Aberto });

        await db.SaveChangesAsync(); // o índice parcial só cobre os abertos
        Assert.Equal(1, await db.Caixas.CountAsync(c => c.Status == StatusCaixa.Aberto));
    }

    // ----- Baixa de estoque atômica na venda -----

    [SkippableFact]
    public async Task Venda_nao_deixa_estoque_ficar_negativo()
    {
        PrecisaDeBanco();

        Guid produtoId;
        await using (var db = NovoContexto())
        {
            db.Caixas.Add(new Caixa { ValorAbertura = 0m, Status = StatusCaixa.Aberto });
            var prod = new Produto { Nome = "Água", Categoria = "Bebida", Preco = 5m, EstoqueQuantidade = 5, Ativo = true };
            db.Produtos.Add(prod);
            await db.SaveChangesAsync();
            produtoId = prod.Id;
        }

        async Task<(Venda? venda, string? erro)> Vender(int qtd)
        {
            await using var db = NovoContexto();
            var req = new VendaCreateRequest(new List<VendaItemRequest> { new(produtoId, qtd) });
            return await new VendaService(db).RegistrarAsync(req, Guid.NewGuid());
        }

        var (venda1, erro1) = await Vender(3);
        Assert.Null(erro1);
        Assert.NotNull(venda1);

        // Só restam 2: uma segunda venda de 3 não pode passar.
        var (venda2, erro2) = await Vender(3);
        Assert.Null(venda2);
        Assert.Contains("Estoque insuficiente", erro2);

        await using var conf = NovoContexto();
        var estoque = (await conf.Produtos.FindAsync(produtoId))!.EstoqueQuantidade;
        Assert.Equal(2, estoque);
    }
}
