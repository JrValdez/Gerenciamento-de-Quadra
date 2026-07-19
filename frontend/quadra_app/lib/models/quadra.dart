class Quadra {
  final String id;
  final String nome;
  final double precoHora;
  final int horaAbertura;
  final int horaFechamento;
  final bool ativa;
  final String? observacoes;

  Quadra({
    required this.id,
    required this.nome,
    required this.precoHora,
    required this.horaAbertura,
    required this.horaFechamento,
    required this.ativa,
    this.observacoes,
  });

  factory Quadra.fromJson(Map<String, dynamic> j) => Quadra(
        id: j['id'],
        nome: j['nome'] ?? '',
        precoHora: (j['precoHora'] as num).toDouble(),
        horaAbertura: j['horaAbertura'] ?? 8,
        horaFechamento: j['horaFechamento'] ?? 22,
        ativa: j['ativa'] ?? true,
        observacoes: j['observacoes'],
      );
}
