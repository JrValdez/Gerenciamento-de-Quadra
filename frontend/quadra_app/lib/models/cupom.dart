// Cupons de desconto.
import 'enum_wire.dart';

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
        tipo: enumIndex(j['tipo'], tipoDescontoNames),
        valor: (j['valor'] as num).toDouble(),
        validoAte: DateTime.parse(j['validoAte']).toLocal(),
        ativo: j['ativo'] ?? true,
        valido: j['valido'] ?? false,
      );
}
