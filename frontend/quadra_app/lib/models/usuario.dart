/// Fonte única das categorias (papéis) de usuário do sistema.
/// Espelha `Roles.All` do backend. Para incluir uma nova categoria,
/// basta adicioná-la aqui: ela passa a aparecer no cadastro de usuário
/// e no filtro da tela de Usuários automaticamente.
const List<String> kCategoriasUsuario = [
  'Admin',
  'Atendente',
  'Professor',
  'Aluno',
  'Cliente',
];

class Usuario {
  final String id;
  final String nomeCompleto;
  final String email;
  final String telefone;
  final List<String> papeis;
  final bool ativo;

  Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    this.telefone = '',
    required this.papeis,
    required this.ativo,
  });

  bool get isAdmin => papeis.contains('Admin');
  bool get isAtendente => papeis.contains('Atendente');
  bool get isProfessor => papeis.contains('Professor');
  bool get isAluno => papeis.contains('Aluno');
  bool get isInterno => isAdmin || isAtendente;
  bool get isCliente => papeis.contains('Cliente');

  /// Quem acessa o painel administrativo (equipe + professor).
  bool get isPainel => isAdmin || isAtendente || isProfessor;

  /// Quem pode gerenciar a competição.
  bool get isGestorCompeticao => isAdmin || isAtendente || isProfessor;

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'],
        nomeCompleto: j['nomeCompleto'] ?? '',
        email: j['email'] ?? '',
        telefone: j['telefone'] ?? '',
        papeis: (j['papeis'] as List?)?.map((e) => e.toString()).toList() ?? [],
        ativo: j['ativo'] ?? true,
      );
}
