const statusAgendamentoLabels = ['Pendente', 'Confirmado', 'Concluído', 'Cancelado'];

class Agendamento {
  final String id;
  final String quadraId;
  final String quadraNome;
  final DateTime inicio;
  final DateTime fim;
  final String nomeCliente;
  final String telefoneCliente;
  final String emailCliente;
  final int status;
  final double valorTotal;
  final double valorDesconto;
  final String? cupomCodigo;
  final String? observacoes;
  final DateTime criadoEm;

  Agendamento({
    required this.id,
    required this.quadraId,
    required this.quadraNome,
    required this.inicio,
    required this.fim,
    required this.nomeCliente,
    required this.telefoneCliente,
    required this.emailCliente,
    required this.status,
    required this.valorTotal,
    this.valorDesconto = 0,
    this.cupomCodigo,
    this.observacoes,
    required this.criadoEm,
  });

  String get statusLabel => statusAgendamentoLabels[status];

  factory Agendamento.fromJson(Map<String, dynamic> j) => Agendamento(
        id: j['id'],
        quadraId: j['quadraId'],
        quadraNome: j['quadraNome'] ?? '',
        inicio: DateTime.parse(j['inicio']).toLocal(),
        fim: DateTime.parse(j['fim']).toLocal(),
        nomeCliente: j['nomeCliente'] ?? '',
        telefoneCliente: j['telefoneCliente'] ?? '',
        emailCliente: j['emailCliente'] ?? '',
        status: j['status'] ?? 0,
        valorTotal: (j['valorTotal'] as num).toDouble(),
        valorDesconto: (j['valorDesconto'] as num?)?.toDouble() ?? 0,
        cupomCodigo: j['cupomCodigo'],
        observacoes: j['observacoes'],
        criadoEm: DateTime.parse(j['criadoEm']).toLocal(),
      );
}

class Slot {
  final DateTime inicio;
  final DateTime fim;
  final bool disponivel;
  Slot({required this.inicio, required this.fim, required this.disponivel});

  factory Slot.fromJson(Map<String, dynamic> j) => Slot(
        inicio: DateTime.parse(j['inicio']).toLocal(),
        fim: DateTime.parse(j['fim']).toLocal(),
        disponivel: j['disponivel'] ?? false,
      );
}
