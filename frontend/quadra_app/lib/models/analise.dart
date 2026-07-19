// Análises financeiras (Dashboard admin).

class PeriodoResumo {
  final double entradas;
  final double saidas;
  final double saldo;
  final int movimentacoes;
  PeriodoResumo(
      {required this.entradas,
      required this.saidas,
      required this.saldo,
      required this.movimentacoes});
  factory PeriodoResumo.fromJson(Map<String, dynamic> j) => PeriodoResumo(
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
        saldo: (j['saldo'] as num?)?.toDouble() ?? 0,
        movimentacoes: j['movimentacoes'] ?? 0,
      );
}

class FluxoDia {
  final DateTime dia;
  final double entradas;
  final double saidas;
  final double saldo;
  FluxoDia({required this.dia, required this.entradas, required this.saidas, required this.saldo});
  factory FluxoDia.fromJson(Map<String, dynamic> j) => FluxoDia(
        dia: DateTime.parse(j['dia']).toLocal(),
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
        saldo: (j['saldo'] as num?)?.toDouble() ?? 0,
      );
}

class CategoriaResumo {
  final String categoria;
  final double entradas;
  final double saidas;
  CategoriaResumo({required this.categoria, required this.entradas, required this.saidas});
  factory CategoriaResumo.fromJson(Map<String, dynamic> j) => CategoriaResumo(
        categoria: j['categoria'] ?? '',
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
      );
}

class FormaPagamentoResumo {
  final String forma;
  final double total;
  FormaPagamentoResumo({required this.forma, required this.total});
  factory FormaPagamentoResumo.fromJson(Map<String, dynamic> j) => FormaPagamentoResumo(
        forma: j['forma'] ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}

class AnaliseCaixa {
  final PeriodoResumo dia;
  final PeriodoResumo semana;
  final PeriodoResumo mes;
  final bool caixaAberto;
  final double? saldoCaixaAtual;
  final List<FluxoDia> fluxoDiario;
  final List<CategoriaResumo> porCategoria;
  final List<FormaPagamentoResumo> porFormaPagamento;
  AnaliseCaixa({
    required this.dia,
    required this.semana,
    required this.mes,
    required this.caixaAberto,
    required this.saldoCaixaAtual,
    required this.fluxoDiario,
    required this.porCategoria,
    required this.porFormaPagamento,
  });
  factory AnaliseCaixa.fromJson(Map<String, dynamic> j) => AnaliseCaixa(
        dia: PeriodoResumo.fromJson(j['dia']),
        semana: PeriodoResumo.fromJson(j['semana']),
        mes: PeriodoResumo.fromJson(j['mes']),
        caixaAberto: j['caixaAberto'] ?? false,
        saldoCaixaAtual: (j['saldoCaixaAtual'] as num?)?.toDouble(),
        fluxoDiario:
            (j['fluxoDiario'] as List?)?.map((e) => FluxoDia.fromJson(e)).toList() ?? [],
        porCategoria:
            (j['porCategoria'] as List?)?.map((e) => CategoriaResumo.fromJson(e)).toList() ?? [],
        porFormaPagamento: (j['porFormaPagamento'] as List?)
                ?.map((e) => FormaPagamentoResumo.fromJson(e))
                .toList() ??
            [],
      );
}
