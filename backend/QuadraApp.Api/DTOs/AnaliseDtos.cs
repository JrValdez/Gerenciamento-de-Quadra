namespace QuadraApp.Api.DTOs;

/// <summary>Totais de um período (dia/semana/mês).</summary>
public record PeriodoResumo(decimal Entradas, decimal Saidas, decimal Saldo, int Movimentacoes);

/// <summary>Fluxo de caixa de um dia (para o gráfico).</summary>
public record FluxoDia(DateTime Dia, decimal Entradas, decimal Saidas, decimal Saldo);

/// <summary>Total de entradas/saídas por categoria de movimentação.</summary>
public record CategoriaResumo(string Categoria, decimal Entradas, decimal Saidas);

/// <summary>Total recebido por forma de pagamento.</summary>
public record FormaPagamentoResumo(string Forma, decimal Total);

/// <summary>Painel de análises financeiras do caixa.</summary>
public record AnaliseCaixaDto(
    PeriodoResumo Dia,
    PeriodoResumo Semana,
    PeriodoResumo Mes,
    bool CaixaAberto,
    decimal? SaldoCaixaAtual,
    IEnumerable<FluxoDia> FluxoDiario,
    IEnumerable<CategoriaResumo> PorCategoria,
    IEnumerable<FormaPagamentoResumo> PorFormaPagamento);
