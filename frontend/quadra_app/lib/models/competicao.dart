// Competição: modalidades, competidores, classificação e lançamentos de pontos.
import 'enum_wire.dart';

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
        tipo: enumIndex(j['tipo'], tipoCompetidorNames),
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
        tipo: enumIndex(j['tipo'], tipoCompetidorNames),
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
