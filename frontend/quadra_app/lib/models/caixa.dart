class Caixa {
  final String id;
  final DateTime abertoEm;
  final DateTime? fechadoEm;
  final double valorAbertura;
  final double? valorFechamentoInformado;
  final int status; // 0 aberto, 1 fechado
  final String? observacoes;
  final double totalEntradas;
  final double totalSaidas;
  final double saldoEsperado;

  Caixa({
    required this.id,
    required this.abertoEm,
    this.fechadoEm,
    required this.valorAbertura,
    this.valorFechamentoInformado,
    required this.status,
    this.observacoes,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldoEsperado,
  });

  bool get aberto => status == 0;

  factory Caixa.fromJson(Map<String, dynamic> j) => Caixa(
        id: j['id'],
        abertoEm: DateTime.parse(j['abertoEm']).toLocal(),
        fechadoEm: j['fechadoEm'] != null ? DateTime.parse(j['fechadoEm']).toLocal() : null,
        valorAbertura: (j['valorAbertura'] as num).toDouble(),
        valorFechamentoInformado: j['valorFechamentoInformado'] != null
            ? (j['valorFechamentoInformado'] as num).toDouble()
            : null,
        status: j['status'] ?? 0,
        observacoes: j['observacoes'],
        totalEntradas: (j['totalEntradas'] as num).toDouble(),
        totalSaidas: (j['totalSaidas'] as num).toDouble(),
        saldoEsperado: (j['saldoEsperado'] as num).toDouble(),
      );
}

const formaPagamentoLabels = ['Dinheiro', 'Cartão', 'Pix'];

class Movimentacao {
  final String id;
  final int tipo; // 0 entrada, 1 saida
  final String categoria;
  final double valor;
  final String descricao;
  final int formaPagamento;
  final DateTime criadoEm;

  Movimentacao({
    required this.id,
    required this.tipo,
    required this.categoria,
    required this.valor,
    required this.descricao,
    required this.formaPagamento,
    required this.criadoEm,
  });

  bool get entrada => tipo == 0;

  factory Movimentacao.fromJson(Map<String, dynamic> j) => Movimentacao(
        id: j['id'],
        tipo: j['tipo'] ?? 0,
        categoria: j['categoria'] ?? '',
        valor: (j['valor'] as num).toDouble(),
        descricao: j['descricao'] ?? '',
        formaPagamento: j['formaPagamento'] ?? 0,
        criadoEm: DateTime.parse(j['criadoEm']).toLocal(),
      );
}
