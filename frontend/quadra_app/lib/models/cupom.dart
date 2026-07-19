// Cupons de desconto.
const tipoDescontoLabels = ['Percentual', 'Valor fixo'];

class Cupom {
  final String id;
  final String codigo;
  final String? descricao;
  final int tipo; // 0 = Percentual, 1 = Valor fixo
  final double valor;
  final DateTime validoAte;
  final bool ativo;
  final bool valido; // ativo e dentro do prazo

  Cupom({
    required this.id,
    required this.codigo,
    this.descricao,
    required this.tipo,
    required this.valor,
    required this.validoAte,
    required this.ativo,
    required this.valido,
  });

  factory Cupom.fromJson(Map<String, dynamic> j) => Cupom(
        id: j['id'],
        codigo: j['codigo'] ?? '',
        descricao: j['descricao'],
        tipo: j['tipo'] ?? 0,
        valor: (j['valor'] as num).toDouble(),
        validoAte: DateTime.parse(j['validoAte']).toLocal(),
        ativo: j['ativo'] ?? true,
        valido: j['valido'] ?? false,
      );
}
