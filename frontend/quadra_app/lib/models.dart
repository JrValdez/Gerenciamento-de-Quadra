// Modelos de dados espelhando os DTOs da API .NET.

// ----- Análises financeiras (Dashboard admin) -----
class PeriodoResumo {
  final double entradas;
  final double saidas;
  final double saldo;
  final int movimentacoes;
  PeriodoResumo(
      {required this.entradas,
      required this.saidas,
      required this.saldo,
      required this.movimentacoes});
  factory PeriodoResumo.fromJson(Map<String, dynamic> j) => PeriodoResumo(
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
        saldo: (j['saldo'] as num?)?.toDouble() ?? 0,
        movimentacoes: j['movimentacoes'] ?? 0,
      );
}

class FluxoDia {
  final DateTime dia;
  final double entradas;
  final double saidas;
  final double saldo;
  FluxoDia({required this.dia, required this.entradas, required this.saidas, required this.saldo});
  factory FluxoDia.fromJson(Map<String, dynamic> j) => FluxoDia(
        dia: DateTime.parse(j['dia']).toLocal(),
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
        saldo: (j['saldo'] as num?)?.toDouble() ?? 0,
      );
}

class CategoriaResumo {
  final String categoria;
  final double entradas;
  final double saidas;
  CategoriaResumo({required this.categoria, required this.entradas, required this.saidas});
  factory CategoriaResumo.fromJson(Map<String, dynamic> j) => CategoriaResumo(
        categoria: j['categoria'] ?? '',
        entradas: (j['entradas'] as num?)?.toDouble() ?? 0,
        saidas: (j['saidas'] as num?)?.toDouble() ?? 0,
      );
}

class FormaPagamentoResumo {
  final String forma;
  final double total;
  FormaPagamentoResumo({required this.forma, required this.total});
  factory FormaPagamentoResumo.fromJson(Map<String, dynamic> j) => FormaPagamentoResumo(
        forma: j['forma'] ?? '',
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}

class AnaliseCaixa {
  final PeriodoResumo dia;
  final PeriodoResumo semana;
  final PeriodoResumo mes;
  final bool caixaAberto;
  final double? saldoCaixaAtual;
  final List<FluxoDia> fluxoDiario;
  final List<CategoriaResumo> porCategoria;
  final List<FormaPagamentoResumo> porFormaPagamento;
  AnaliseCaixa({
    required this.dia,
    required this.semana,
    required this.mes,
    required this.caixaAberto,
    required this.saldoCaixaAtual,
    required this.fluxoDiario,
    required this.porCategoria,
    required this.porFormaPagamento,
  });
  factory AnaliseCaixa.fromJson(Map<String, dynamic> j) => AnaliseCaixa(
        dia: PeriodoResumo.fromJson(j['dia']),
        semana: PeriodoResumo.fromJson(j['semana']),
        mes: PeriodoResumo.fromJson(j['mes']),
        caixaAberto: j['caixaAberto'] ?? false,
        saldoCaixaAtual: (j['saldoCaixaAtual'] as num?)?.toDouble(),
        fluxoDiario:
            (j['fluxoDiario'] as List?)?.map((e) => FluxoDia.fromJson(e)).toList() ?? [],
        porCategoria:
            (j['porCategoria'] as List?)?.map((e) => CategoriaResumo.fromJson(e)).toList() ?? [],
        porFormaPagamento: (j['porFormaPagamento'] as List?)
                ?.map((e) => FormaPagamentoResumo.fromJson(e))
                .toList() ??
            [],
      );
}

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

// ----- Cupons de desconto -----
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
  final String telefone;
  AlunoRef({required this.id, required this.nome, required this.email, this.telefone = ''});
  factory AlunoRef.fromJson(Map<String, dynamic> j) => AlunoRef(
        id: j['id'],
        nome: j['nome'] ?? '',
        email: j['email'] ?? '',
        telefone: j['telefone'] ?? '',
      );
}

class Professor {
  final String id;
  final String nomeCompleto;
  final String email;
  final double precoAula;
  final bool ativo;
  Professor({
    required this.id,
    required this.nomeCompleto,
    required this.email,
    required this.precoAula,
    required this.ativo,
  });
  factory Professor.fromJson(Map<String, dynamic> j) => Professor(
        id: j['id'],
        nomeCompleto: j['nomeCompleto'] ?? '',
        email: j['email'] ?? '',
        precoAula: (j['precoAula'] as num?)?.toDouble() ?? 0,
        ativo: j['ativo'] ?? true,
      );
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
