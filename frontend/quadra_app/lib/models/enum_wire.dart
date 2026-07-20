// Leitura de enums vindos da API. O backend passou a serializar enums como string
// (ex.: "Confirmado" em vez de 1) — contrato legível e resistente a reordenação.
// Estas listas espelham os NOMES dos membros no C# (na ordem da enum) e o helper
// converte o valor recebido (nome ou, por retrocompatibilidade, inteiro) no índice
// inteiro que o restante do app já usa. O envio continua em inteiro, que o backend
// também aceita.

const statusAgendamentoNames = ['Pendente', 'Confirmado', 'Concluido', 'Cancelado'];
const statusCaixaNames = ['Aberto', 'Fechado'];
const tipoMovimentacaoNames = ['Entrada', 'Saida'];
const formaPagamentoNames = ['Dinheiro', 'Cartao', 'Pix'];
const tipoDescontoNames = ['Percentual', 'ValorFixo'];
const tipoCompetidorNames = ['Individual', 'Equipe'];

/// Converte o valor de enum recebido no JSON (nome em string ou inteiro) para o
/// índice inteiro correspondente. Cai em 0 se não reconhecer.
int enumIndex(dynamic value, List<String> wireNames) {
  if (value is int) return value;
  if (value is String) {
    final i = wireNames.indexWhere((n) => n.toLowerCase() == value.toLowerCase());
    if (i >= 0) return i;
    final n = int.tryParse(value);
    if (n != null) return n;
  }
  return 0;
}
