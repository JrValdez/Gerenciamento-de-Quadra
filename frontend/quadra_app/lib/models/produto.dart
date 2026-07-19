class Produto {
  final String id;
  final String nome;
  final String? descricao;
  final String categoria;
  final double preco;
  final int estoqueQuantidade;
  final bool ativo;

  Produto({
    required this.id,
    required this.nome,
    this.descricao,
    required this.categoria,
    required this.preco,
    required this.estoqueQuantidade,
    required this.ativo,
  });

  factory Produto.fromJson(Map<String, dynamic> j) => Produto(
        id: j['id'],
        nome: j['nome'] ?? '',
        descricao: j['descricao'],
        categoria: j['categoria'] ?? 'Geral',
        preco: (j['preco'] as num).toDouble(),
        estoqueQuantidade: j['estoqueQuantidade'] ?? 0,
        ativo: j['ativo'] ?? true,
      );
}
