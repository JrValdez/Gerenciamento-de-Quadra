import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';
import 'models.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

/// Cliente central da API. Guarda o token JWT em memória.
class ApiClient {
  String? _token;
  void setToken(String? token) => _token = token;

  Map<String, String> _headers({bool json = true}) => {
        if (json) 'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = query?.map((k, v) => MapEntry(k, '$v'));
    return Uri.parse('$kApiBaseUrl$path').replace(queryParameters: q);
  }

  Never _throw(http.Response r) {
    String msg = 'Erro ${r.statusCode}';
    try {
      final body = jsonDecode(r.body);
      if (body is Map && body['erro'] != null) {
        msg = body['erro'];
      } else if (body is Map && body['mensagem'] != null) {
        msg = body['mensagem'];
      }
    } catch (_) {}
    throw ApiException(r.statusCode, msg);
  }

  dynamic _decode(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    _throw(r);
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async =>
      _decode(await http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> _post(String path, Object? body) async =>
      _decode(await http.post(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> _put(String path, Object? body) async =>
      _decode(await http.put(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> _patch(String path, Object? body) async =>
      _decode(await http.patch(_uri(path), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> _delete(String path) async =>
      _decode(await http.delete(_uri(path), headers: _headers()));

  // ---------- Auth ----------
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final data = await _post('/auth/login', {'email': email, 'senha': senha});
    return data as Map<String, dynamic>;
  }

  Future<Usuario> me() async => Usuario.fromJson(await _get('/auth/me'));

  /// Solicita o envio do link de redefinição de senha.
  Future<void> esqueciSenha(String email) async =>
      await _post('/auth/forgot-password', {'email': email});

  /// Redefine a senha usando o token recebido por e-mail.
  Future<void> redefinirSenha(String email, String token, String novaSenha) async =>
      await _post('/auth/reset-password',
          {'email': email, 'token': token, 'novaSenha': novaSenha});

  Future<Usuario> registrar(String nome, String email, String senha, String papel) async =>
      Usuario.fromJson(await _post('/auth/register',
          {'nomeCompleto': nome, 'email': email, 'senha': senha, 'papel': papel}));

  Future<List<Usuario>> usuarios() async {
    final data = await _get('/auth/usuarios');
    return (data as List).map((e) => Usuario.fromJson(e)).toList();
  }

  Future<Usuario> definirAtivo(String id, bool ativo) async =>
      Usuario.fromJson(await _patch('/auth/usuarios/$id/ativo', {'ativo': ativo}));

  Future<Usuario> editarUsuario(String id, String nome, String email, String telefone) async =>
      Usuario.fromJson(await _put('/auth/usuarios/$id',
          {'nomeCompleto': nome, 'email': email, 'telefone': telefone}));

  Future<Usuario> definirPapel(String id, String papel) async =>
      Usuario.fromJson(await _put('/auth/usuarios/$id/papel', {'papel': papel}));

  Future<void> excluirUsuario(String id) async => await _delete('/auth/usuarios/$id');

  // ---------- Dashboard ----------
  Future<DashboardResumo> dashboard() async =>
      DashboardResumo.fromJson(await _get('/dashboard/resumo'));

  // ---------- Análises (admin) ----------
  Future<AnaliseCaixa> analiseCaixa() async =>
      AnaliseCaixa.fromJson(await _get('/analise/caixa'));

  // ---------- Quadras ----------
  Future<List<Quadra>> quadras({bool incluirInativas = false}) async {
    final data = await _get('/quadras', {'incluirInativas': incluirInativas});
    return (data as List).map((e) => Quadra.fromJson(e)).toList();
  }

  Future<Quadra> criarQuadra(Map<String, dynamic> body) async =>
      Quadra.fromJson(await _post('/quadras', body));

  Future<Quadra> atualizarQuadra(String id, Map<String, dynamic> body) async =>
      Quadra.fromJson(await _put('/quadras/$id', body));

  Future<void> excluirQuadra(String id) async => await _delete('/quadras/$id');

  // ---------- Agendamentos ----------
  Future<Agendamento> agendarPublico(Map<String, dynamic> body) async =>
      Agendamento.fromJson(await _post('/agendamentos/publico', body));

  Future<List<Slot>> disponibilidade(String quadraId, DateTime dia, {int slotMinutos = 60}) async {
    final data = await _get('/agendamentos/disponibilidade', {
      'quadraId': quadraId,
      'dia': dia.toIso8601String(),
      'slotMinutos': slotMinutos,
    });
    return (data as List).map((e) => Slot.fromJson(e)).toList();
  }

  Future<List<Agendamento>> agendamentos({DateTime? de, DateTime? ate, int? status}) async {
    final q = <String, dynamic>{};
    if (de != null) q['de'] = de.toUtc().toIso8601String();
    if (ate != null) q['ate'] = ate.toUtc().toIso8601String();
    if (status != null) q['status'] = status;
    final data = await _get('/agendamentos', q);
    return (data as List).map((e) => Agendamento.fromJson(e)).toList();
  }

  Future<Agendamento> criarAgendamento(Map<String, dynamic> body) async =>
      Agendamento.fromJson(await _post('/agendamentos', body));

  Future<Agendamento> alterarStatusAgendamento(String id, int status) async =>
      Agendamento.fromJson(await _patch('/agendamentos/$id/status', {'status': status}));

  /// Reserva de quadra feita pelo professor logado para dar aula.
  Future<Agendamento> reservarAula(Map<String, dynamic> body) async =>
      Agendamento.fromJson(await _post('/agendamentos/aula', body));

  // ---------- Professores ----------
  Future<List<Professor>> professores() async {
    final data = await _get('/professores');
    return (data as List).map((e) => Professor.fromJson(e)).toList();
  }

  Future<Professor> meuPrecoAula() async =>
      Professor.fromJson(await _get('/professores/me'));

  Future<Professor> definirPrecoProfessor(String id, double precoAula) async =>
      Professor.fromJson(await _put('/professores/$id/preco', {'precoAula': precoAula}));

  // ---------- Bloqueios ----------
  Future<List<Bloqueio>> bloqueios({String? quadraId, bool incluirPassados = false}) async {
    final q = <String, dynamic>{'incluirPassados': incluirPassados};
    if (quadraId != null) q['quadraId'] = quadraId;
    final data = await _get('/bloqueios', q);
    return (data as List).map((e) => Bloqueio.fromJson(e)).toList();
  }

  Future<Bloqueio> criarBloqueio(Map<String, dynamic> body) async =>
      Bloqueio.fromJson(await _post('/bloqueios', body));

  Future<void> excluirBloqueio(String id) async => await _delete('/bloqueios/$id');

  // ---------- Cupons ----------
  Future<List<Cupom>> cupons({bool incluirInativos = false}) async {
    final data = await _get('/cupons', {'incluirInativos': incluirInativos});
    return (data as List).map((e) => Cupom.fromJson(e)).toList();
  }

  Future<Cupom> criarCupom(Map<String, dynamic> body) async =>
      Cupom.fromJson(await _post('/cupons', body));

  Future<Cupom> atualizarCupom(String id, Map<String, dynamic> body) async =>
      Cupom.fromJson(await _put('/cupons/$id', body));

  Future<void> excluirCupom(String id) async => await _delete('/cupons/$id');

  /// Valida um cupom pelo código; lança [ApiException] se inválido/expirado.
  Future<Cupom> validarCupom(String codigo) async =>
      Cupom.fromJson(await _get('/cupons/validar/${Uri.encodeComponent(codigo)}'));

  // ---------- Produtos ----------
  Future<List<Produto>> produtos({bool incluirInativos = false}) async {
    final data = await _get('/produtos', {'incluirInativos': incluirInativos});
    return (data as List).map((e) => Produto.fromJson(e)).toList();
  }

  Future<Produto> criarProduto(Map<String, dynamic> body) async =>
      Produto.fromJson(await _post('/produtos', body));

  Future<Produto> atualizarProduto(String id, Map<String, dynamic> body) async =>
      Produto.fromJson(await _put('/produtos/$id', body));

  Future<void> excluirProduto(String id) async => await _delete('/produtos/$id');

  // ---------- Caixa ----------
  Future<Caixa?> caixaAtual() async {
    final data = await _get('/caixa/atual');
    return data == null ? null : Caixa.fromJson(data);
  }

  Future<List<Caixa>> caixas() async {
    final data = await _get('/caixa');
    return (data as List).map((e) => Caixa.fromJson(e)).toList();
  }

  Future<Caixa> abrirCaixa(double valorAbertura, [String? obs]) async =>
      Caixa.fromJson(await _post('/caixa/abrir', {'valorAbertura': valorAbertura, 'observacoes': obs}));

  Future<Caixa> fecharCaixa(double valorInformado, [String? obs]) async =>
      Caixa.fromJson(await _post('/caixa/fechar', {'valorFechamentoInformado': valorInformado, 'observacoes': obs}));

  Future<List<Movimentacao>> movimentacoes(String caixaId) async {
    final data = await _get('/caixa/$caixaId/movimentacoes');
    return (data as List).map((e) => Movimentacao.fromJson(e)).toList();
  }

  Future<void> lancarMovimentacao(Map<String, dynamic> body) async =>
      await _post('/caixa/movimentacoes', body);

  // ---------- Vendas ----------
  Future<void> registrarVenda(Map<String, dynamic> body) async =>
      await _post('/vendas', body);

  // ---------- Competição ----------
  Future<List<Modalidade>> modalidades({bool incluirInativas = false}) async {
    final data = await _get('/modalidades', {'incluirInativas': incluirInativas});
    return (data as List).map((e) => Modalidade.fromJson(e)).toList();
  }

  Future<Modalidade> criarModalidade(String nome) async =>
      Modalidade.fromJson(await _post('/modalidades', {'nome': nome, 'ativa': true}));

  Future<Modalidade> atualizarModalidade(String id, String nome, bool ativa) async =>
      Modalidade.fromJson(await _put('/modalidades/$id', {'nome': nome, 'ativa': ativa}));

  Future<void> excluirModalidade(String id) async => await _delete('/modalidades/$id');

  Future<List<AlunoRef>> alunos() async {
    final data = await _get('/competicao/alunos');
    return (data as List).map((e) => AlunoRef.fromJson(e)).toList();
  }

  /// Criação de aluno pelo professor (papel sempre Aluno).
  Future<AlunoRef> criarAluno(String nome, String email, String telefone, String senha) async =>
      AlunoRef.fromJson(await _post('/professores/alunos',
          {'nomeCompleto': nome, 'email': email, 'telefone': telefone, 'senha': senha}));

  Future<List<Competidor>> competidores(String modalidadeId) async {
    final data = await _get('/competicao/competidores', {'modalidadeId': modalidadeId});
    return (data as List).map((e) => Competidor.fromJson(e)).toList();
  }

  Future<Competidor> criarCompetidor(Map<String, dynamic> body) async =>
      Competidor.fromJson(await _post('/competicao/competidores', body));

  Future<void> excluirCompetidor(String id) async =>
      await _delete('/competicao/competidores/$id');

  Future<void> lancarPontos(String competidorId, int pontos, String motivo) async =>
      await _post('/competicao/lancamentos',
          {'competidorId': competidorId, 'pontos': pontos, 'motivo': motivo});

  Future<List<Lancamento>> lancamentos(String modalidadeId, {String? competidorId}) async {
    final q = <String, dynamic>{'modalidadeId': modalidadeId};
    if (competidorId != null) q['competidorId'] = competidorId;
    final data = await _get('/competicao/lancamentos', q);
    return (data as List).map((e) => Lancamento.fromJson(e)).toList();
  }

  Future<List<ClassificacaoItem>> classificacao(String modalidadeId, {int? tipo}) async {
    final q = <String, dynamic>{'modalidadeId': modalidadeId};
    if (tipo != null) q['tipo'] = tipo;
    final data = await _get('/competicao/classificacao', q);
    return (data as List).map((e) => ClassificacaoItem.fromJson(e)).toList();
  }
}
