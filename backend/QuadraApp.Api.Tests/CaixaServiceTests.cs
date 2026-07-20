using QuadraApp.Api.Models;
using QuadraApp.Api.Services;
using Xunit;

namespace QuadraApp.Api.Tests;

/// <summary>
/// Cobre o cálculo puro do saldo de caixa (abertura + entradas − saídas), extraído
/// do controller para <see cref="CaixaService.Totais"/> e agora testável sem banco.
/// </summary>
public class CaixaServiceTests
{
    private static MovimentacaoCaixa Mov(TipoMovimentacao tipo, decimal valor) =>
        new() { Tipo = tipo, Valor = valor };

    [Fact]
    public void Totais_soma_entradas_subtrai_saidas_sobre_abertura()
    {
        var caixa = new Caixa
        {
            ValorAbertura = 100m,
            Movimentacoes = new List<MovimentacaoCaixa>
            {
                Mov(TipoMovimentacao.Entrada, 50m),
                Mov(TipoMovimentacao.Entrada, 30m),
                Mov(TipoMovimentacao.Saida, 20m),
            },
        };

        var (entradas, saidas, saldo) = CaixaService.Totais(caixa);

        Assert.Equal(80m, entradas);
        Assert.Equal(20m, saidas);
        Assert.Equal(160m, saldo); // 100 + 80 - 20
    }

    [Fact]
    public void Totais_sem_movimentacoes_devolve_apenas_a_abertura()
    {
        var caixa = new Caixa { ValorAbertura = 250m };

        var (entradas, saidas, saldo) = CaixaService.Totais(caixa);

        Assert.Equal(0m, entradas);
        Assert.Equal(0m, saidas);
        Assert.Equal(250m, saldo);
    }

    [Fact]
    public void Totais_saldo_pode_ficar_negativo_com_sangria_maior_que_o_disponivel()
    {
        var caixa = new Caixa
        {
            ValorAbertura = 10m,
            Movimentacoes = new List<MovimentacaoCaixa> { Mov(TipoMovimentacao.Saida, 40m) },
        };

        var (_, _, saldo) = CaixaService.Totais(caixa);

        Assert.Equal(-30m, saldo);
    }
}
