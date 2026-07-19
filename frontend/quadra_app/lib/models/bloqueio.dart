class Bloqueio {
  final String id;
  final String quadraId;
  final String quadraNome;
  final DateTime inicio;
  final DateTime fim;
  final String? motivo;

  Bloqueio({
    required this.id,
    required this.quadraId,
    required this.quadraNome,
    required this.inicio,
    required this.fim,
    this.motivo,
  });

  factory Bloqueio.fromJson(Map<String, dynamic> j) => Bloqueio(
        id: j['id'],
        quadraId: j['quadraId'],
        quadraNome: j['quadraNome'] ?? '',
        inicio: DateTime.parse(j['inicio']).toLocal(),
        fim: DateTime.parse(j['fim']).toLocal(),
        motivo: j['motivo'],
      );
}
