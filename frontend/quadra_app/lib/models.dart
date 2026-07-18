// Modelos de dados espelhando os DTOs da API .NET.

class Usuario {
  final String id;
  final String nomeCompleto;
  final String email;
  final List<String> papeis;
  final bool ativo;

  Usuario({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    required this.papeis,
    required this.ativo,
  });

  bool get isAdmin => papeis.contains('Admin');
  bool get isAtendente => papeis.contains('Atendente');
  bool get isProfessor => papeis.contains('Professor');
  bool get isAluno => papeis.contains('Aluno');
  bool get isInterno => isAdmin || isAtendente;

  /// Quem acessa o painel administrativo (equipe + professor).
  bool get isPainel => isAdmin || isAtendente || isProfessor;

  /// Quem pode gerenciar a competição.
  bool get isGestorCompeticao => isAdmin || isAtendente || isProfessor;

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: j['id'],
        nomeCompleto: j['nomeCompleto'] ?? '',
        email: j['email'] ?? '',
        papeis: (j['papeis'] as List?)?.map((e) => e.toString()).toList() ?? [],
        ativo: j['ativo'] ?? true,
      );
}

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

const formaPagamentoLabels = ['Dinheiro', 'Cartão', 'Pix'];

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

// ----- Competição -----
const tipoCompetidorLabels = ['Individual', 'Equipe'];

class Modalidade {
  final String id;
  final String nome;
  final bool ativa;
  Modalidade({required this.id, required this.nome, required this.ativa});
  factory Modalidade.fromJson(Map<String, dynamic> j) =>
      Modalidade(id: j['id'], nome: j['nome'] ?? '', ativa: j['ativa'] ?? true);
}

class AlunoRef {
  final String id;
  final String nome;
  final String email;
  AlunoRef({required this.id, required this.nome, required this.email});
  factory AlunoRef.fromJson(Map<String, dynamic> j) =>
      AlunoRef(id: j['id'], nome: j['nome'] ?? '', email: j['email'] ?? '');
}

class Membro {
  final String alunoId;
  final String alunoNome;
  Membro({required this.alunoId, required this.alunoNome});
  factory Membro.fromJson(Map<String, dynamic> j) =>
      Membro(alunoId: j['alunoId'], alunoNome: j['alunoNome'] ?? '');
}

class Competidor {
  final String id;
  final String modalidadeId;
  final int tipo; // 0 individual, 1 equipe
  final String nome;
  final bool ativo;
  final List<Membro> membros;
  Competidor({
    required this.id,
    required this.modalidadeId,
    required this.tipo,
    required this.nome,
    required this.ativo,
    required this.membros,
  });
  factory Competidor.fromJson(Map<String, dynamic> j) => Competidor(
        id: j['id'],
        modalidadeId: j['modalidadeId'],
        tipo: j['tipo'] ?? 0,
        nome: j['nome'] ?? '',
        ativo: j['ativo'] ?? true,
        membros: (j['membros'] as List?)?.map((e) => Membro.fromJson(e)).toList() ?? [],
      );
}

class ClassificacaoItem {
  final int posicao;
  final String competidorId;
  final String nome;
  final int tipo;
  final int totalPontos;
  final int qtdLancamentos;
  final List<Membro> membros;
  ClassificacaoItem({
    required this.posicao,
    required this.competidorId,
    required this.nome,
    required this.tipo,
    required this.totalPontos,
    required this.qtdLancamentos,
    required this.membros,
  });
  factory ClassificacaoItem.fromJson(Map<String, dynamic> j) => ClassificacaoItem(
        posicao: j['posicao'] ?? 0,
        competidorId: j['competidorId'],
        nome: j['nome'] ?? '',
        tipo: j['tipo'] ?? 0,
        totalPontos: j['totalPontos'] ?? 0,
        qtdLancamentos: j['qtdLancamentos'] ?? 0,
        membros: (j['membros'] as List?)?.map((e) => Membro.fromJson(e)).toList() ?? [],
      );
}

class Lancamento {
  final String id;
  final String competidorId;
  final String competidorNome;
  final int pontos;
  final String motivo;
  final DateTime data;
  Lancamento({
    required this.id,
    required this.competidorId,
    required this.competidorNome,
    required this.pontos,
    required this.motivo,
    required this.data,
  });
  factory Lancamento.fromJson(Map<String, dynamic> j) => Lancamento(
        id: j['id'],
        competidorId: j['competidorId'],
        competidorNome: j['competidorNome'] ?? '',
        pontos: j['pontos'] ?? 0,
        motivo: j['motivo'] ?? '',
        data: DateTime.parse(j['data']).toLocal(),
      );
}

class DashboardResumo {
  final int agendamentosHoje;
  final int agendamentosPendentes;
  final double faturamentoHoje;
  final bool caixaAberto;
  final double? saldoCaixa;
  final int produtosBaixoEstoque;
  final List<Agendamento> proximosAgendamentos;

  DashboardResumo({
    required this.agendamentosHoje,
    required this.agendamentosPendentes,
    required this.faturamentoHoje,
    required this.caixaAberto,
    this.saldoCaixa,
    required this.produtosBaixoEstoque,
    required this.proximosAgendamentos,
  });

  factory DashboardResumo.fromJson(Map<String, dynamic> j) => DashboardResumo(
        agendamentosHoje: j['agendamentosHoje'] ?? 0,
        agendamentosPendentes: j['agendamentosPendentes'] ?? 0,
        faturamentoHoje: (j['faturamentoHoje'] as num).toDouble(),
        caixaAberto: j['caixaAberto'] ?? false,
        saldoCaixa: j['saldoCaixa'] != null ? (j['saldoCaixa'] as num).toDouble() : null,
        produtosBaixoEstoque: j['produtosBaixoEstoque'] ?? 0,
        proximosAgendamentos: (j['proximosAgendamentos'] as List?)
                ?.map((e) => Agendamento.fromJson(e))
                .toList() ??
            [],
      );
}
