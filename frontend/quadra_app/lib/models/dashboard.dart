import 'agendamento.dart';

class DashboardResumo {
  final int agendamentosHoje;
  final int agendamentosPendentes;
  final double faturamentoHoje;
  final bool caixaAberto;
  final double? saldoCaixa;
  final int produtosBaixoEstoque;
  final List<Agendamento> proximosAgendamentos;

  DashboardResumo({
    required this.agendamentosHoje,
    required this.agendamentosPendentes,
    required this.faturamentoHoje,
    required this.caixaAberto,
    this.saldoCaixa,
    required this.produtosBaixoEstoque,
    required this.proximosAgendamentos,
  });

  factory DashboardResumo.fromJson(Map<String, dynamic> j) => DashboardResumo(
        agendamentosHoje: j['agendamentosHoje'] ?? 0,
        agendamentosPendentes: j['agendamentosPendentes'] ?? 0,
        faturamentoHoje: (j['faturamentoHoje'] as num).toDouble(),
        caixaAberto: j['caixaAberto'] ?? false,
        saldoCaixa: j['saldoCaixa'] != null ? (j['saldoCaixa'] as num).toDouble() : null,
        produtosBaixoEstoque: j['produtosBaixoEstoque'] ?? 0,
        proximosAgendamentos: (j['proximosAgendamentos'] as List?)
                ?.map((e) => Agendamento.fromJson(e))
                .toList() ??
            [],
      );
}
