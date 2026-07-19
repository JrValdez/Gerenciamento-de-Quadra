using QuadraApp.Api.Models;
using QuadraApp.Api.Services;
using Xunit;

namespace QuadraApp.Api.Tests;

/// <summary>
/// Cobre a lógica financeira pura de reserva (valor bruto e desconto de cupom),
/// que antes vivia embutida no controller e não era testável.
/// </summary>
public class AgendamentoServiceTests
{
    private static readonly DateTime Base = new(2026, 8, 1, 10, 0, 0, DateTimeKind.Utc);

    [Theory]
    [InlineData(80, 1, 80)]     // 1 hora a 80/h
    [InlineData(60, 2, 120)]    // 2 horas a 60/h
    [InlineData(50, 3, 150)]    // 3 horas a 50/h
    public void CalcularValor_multiplica_preco_por_horas(double precoHora, int horas, double esperado)
    {
        var valor = AgendamentoService.CalcularValor((decimal)precoHora, Base, Base.AddHours(horas));
        Assert.Equal((decimal)esperado, valor);
    }

    [Fact]
    public void CalcularValor_meia_hora_cobra_metade()
    {
        var valor = AgendamentoService.CalcularValor(80m, Base, Base.AddMinutes(30));
        Assert.Equal(40m, valor);
    }

    [Fact]
    public void CalcularValor_arredonda_para_duas_casas()
    {
        // 1,5h × 33,33 = 49,995 → arredonda para 50,00
        var valor = AgendamentoService.CalcularValor(33.33m, Base, Base.AddMinutes(90));
        Assert.Equal(50.00m, valor);
    }

    [Fact]
    public void CalcularDesconto_percentual_aplica_taxa()
    {
        Assert.Equal(10m, AgendamentoService.CalcularDesconto(TipoDesconto.Percentual, 10m, 100m));
        Assert.Equal(40m, AgendamentoService.CalcularDesconto(TipoDesconto.Percentual, 50m, 80m));
    }

    [Fact]
    public void CalcularDesconto_valor_fixo_abate_direto()
    {
        Assert.Equal(15m, AgendamentoService.CalcularDesconto(TipoDesconto.ValorFixo, 15m, 100m));
    }

    [Fact]
    public void CalcularDesconto_nunca_ultrapassa_o_bruto()
    {
        // Cupom de R$200 num valor de R$100 não deixa o total negativo.
        Assert.Equal(100m, AgendamentoService.CalcularDesconto(TipoDesconto.ValorFixo, 200m, 100m));
        // 150% num valor de R$100 também é limitado a R$100.
        Assert.Equal(100m, AgendamentoService.CalcularDesconto(TipoDesconto.Percentual, 150m, 100m));
    }

    [Fact]
    public void CalcularDesconto_percentual_arredonda_para_duas_casas()
    {
        // 10% de 49,99 = 4,999 → 5,00
        Assert.Equal(5.00m, AgendamentoService.CalcularDesconto(TipoDesconto.Percentual, 10m, 49.99m));
    }
}
