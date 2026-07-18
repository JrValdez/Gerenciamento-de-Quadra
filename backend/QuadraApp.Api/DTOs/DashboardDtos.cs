namespace QuadraApp.Api.DTOs;

public record DashboardResumo(
    int AgendamentosHoje,
    int AgendamentosPendentes,
    decimal FaturamentoHoje,
    bool CaixaAberto,
    decimal? SaldoCaixa,
    int ProdutosBaixoEstoque,
    IEnumerable<AgendamentoDto> ProximosAgendamentos);
