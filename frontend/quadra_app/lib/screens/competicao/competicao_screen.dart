import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api_client.dart';
import '../../models.dart';
import '../../theme.dart';
import 'classificacao_view.dart';

/// Gestão da competição (Admin/Atendente/Professor).
class CompeticaoScreen extends StatelessWidget {
  const CompeticaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.leaderboard), text: 'Classificação'),
              Tab(icon: Icon(Icons.groups), text: 'Competidores'),
              Tab(icon: Icon(Icons.sports), text: 'Modalidades'),
              Tab(icon: Icon(Icons.add_task), text: 'Lançar pontos'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                ClassificacaoView(),
                _CompetidoresTab(),
                _ModalidadesTab(),
                _PontosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================ MODALIDADES ============================
class _ModalidadesTab extends StatefulWidget {
  const _ModalidadesTab();
  @override
  State<_ModalidadesTab> createState() => _ModalidadesTabState();
}

class _ModalidadesTabState extends State<_ModalidadesTab> {
  late final ApiClient api = context.read<ApiClient>();
  final _nova = TextEditingController();
  List<Modalidade> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nova.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens = await api.modalidades(incluirInativas: true);
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _adicionar() async {
    final nome = _nova.text.trim();
    if (nome.isEmpty) return;
    try {
      await api.criarModalidade(nome);
      _nova.clear();
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nova,
                  decoration: const InputDecoration(
                      labelText: 'Nova modalidade', hintText: 'Ex.: Beach Tennis', isDense: true),
                  onSubmitted: (_) => _adicionar(),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                  onPressed: _adicionar, icon: const Icon(Icons.add), label: const Text('Adicionar')),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: _itens
                      .map((m) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.sports, color: Color(0xFF1B7A3D)),
                              title: Text(m.nome),
                              subtitle: Text(m.ativa ? 'Ativa' : 'Inativa'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: m.ativa,
                                    onChanged: (v) async {
                                      try {
                                        await api.atualizarModalidade(m.id, m.nome, v);
                                        _carregar();
                                      } catch (e) {
                                        _msg('Erro: $e');
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () async {
                                      try {
                                        await api.excluirModalidade(m.id);
                                        _carregar();
                                      } catch (e) {
                                        _msg('Erro: $e');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

// ============================ COMPETIDORES ============================
class _CompetidoresTab extends StatefulWidget {
  const _CompetidoresTab();
  @override
  State<_CompetidoresTab> createState() => _CompetidoresTabState();
}

class _CompetidoresTabState extends State<_CompetidoresTab> {
  late final ApiClient api = context.read<ApiClient>();
  List<Modalidade> _modalidades = [];
  Modalidade? _modalidade;
  List<Competidor> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _modalidades = await api.modalidades();
      _modalidade = _modalidades.isNotEmpty ? _modalidades.first : null;
      if (_modalidade != null) await _carregarCompetidores();
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _carregarCompetidores() async {
    if (_modalidade == null) return;
    final r = await api.competidores(_modalidade!.id);
    if (mounted) setState(() => _itens = r);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _adicionar(int tipoInicial) async {
    if (_modalidade == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CompetidorDialog(api: api, modalidade: _modalidade!, tipoInicial: tipoInicial),
    );
    if (ok == true) {
      _msg('Competidor adicionado!');
      _carregarCompetidores();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_modalidades.isEmpty) {
      return const Center(child: Text('Cadastre uma modalidade primeiro.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Row(
            children: [
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<Modalidade>(
                  initialValue: _modalidade,
                  decoration: const InputDecoration(labelText: 'Modalidade', isDense: true),
                  items: _modalidades
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.nome)))
                      .toList(),
                  onChanged: (m) {
                    setState(() => _modalidade = m);
                    _carregarCompetidores();
                  },
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _adicionar(0),
                icon: const Icon(Icons.person_add),
                label: const Text('Individual'),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: () => _adicionar(1),
                icon: const Icon(Icons.groups),
                label: const Text('Adicionar time'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _itens.isEmpty
              ? const Center(child: Text('Nenhum competidor nesta modalidade.'))
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: _itens
                      .map((c) => Card(
                            child: ListTile(
                              leading: Icon(c.tipo == 1 ? Icons.groups : Icons.person,
                                  color: const Color(0xFF1B7A3D)),
                              title: Text(c.nome),
                              subtitle: Text(
                                  '${tipoCompetidorLabels[c.tipo]}'
                                  '${c.membros.isNotEmpty ? ' • ${c.membros.map((m) => m.alunoNome).join(', ')}' : ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () async {
                                  try {
                                    await api.excluirCompetidor(c.id);
                                    _carregarCompetidores();
                                  } catch (e) {
                                    _msg('Erro: $e');
                                  }
                                },
                              ),
                            ),
                          ))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _CompetidorDialog extends StatefulWidget {
  final ApiClient api;
  final Modalidade modalidade;
  final int tipoInicial;
  const _CompetidorDialog({required this.api, required this.modalidade, this.tipoInicial = 0});
  @override
  State<_CompetidorDialog> createState() => _CompetidorDialogState();
}

class _CompetidorDialogState extends State<_CompetidorDialog> {
  late int _tipo = widget.tipoInicial; // 0 individual, 1 equipe
  final _nome = TextEditingController();
  final Set<String> _selecionados = {};
  List<AlunoRef> _alunos = [];
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAlunos();
  }

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  Future<void> _carregarAlunos() async {
    try {
      _alunos = await widget.api.alunos();
    } catch (e) {
      _erro = '$e';
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    if (_tipo == 0 && _selecionados.length != 1) {
      setState(() => _erro = 'Selecione exatamente 1 aluno para individual.');
      return;
    }
    if (_tipo == 1 && _selecionados.isEmpty) {
      setState(() => _erro = 'Selecione ao menos 1 aluno para a equipe.');
      return;
    }
    if (_tipo == 1 && _nome.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o nome da equipe.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.criarCompetidor({
        'modalidadeId': widget.modalidade.id,
        'tipo': _tipo,
        'nome': _tipo == 1 ? _nome.text.trim() : null,
        'alunosIds': _selecionados.toList(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _salvando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao salvar.';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${_tipo == 1 ? 'Novo time' : 'Novo competidor individual'} • ${widget.modalidade.nome}'),
      content: SizedBox(
        width: 440,
        height: 460,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Individual'), icon: Icon(Icons.person)),
                      ButtonSegment(value: 1, label: Text('Equipe'), icon: Icon(Icons.groups)),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: (s) => setState(() {
                      _tipo = s.first;
                      if (_tipo == 0 && _selecionados.length > 1) _selecionados.clear();
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (_tipo == 1)
                    TextField(
                      controller: _nome,
                      decoration: const InputDecoration(labelText: 'Nome da equipe', isDense: true),
                    ),
                  const SizedBox(height: 12),
                  Text(_tipo == 0 ? 'Selecione o aluno:' : 'Selecione os integrantes:',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: _alunos.isEmpty
                        ? const Center(child: Text('Nenhum aluno cadastrado.\nCrie usuários com papel Aluno.',
                            textAlign: TextAlign.center))
                        : ListView(
                            children: _alunos.map((a) {
                              final sel = _selecionados.contains(a.id);
                              return CheckboxListTile(
                                dense: true,
                                value: sel,
                                title: Text(a.nome),
                                subtitle: Text(a.email, style: const TextStyle(fontSize: 12)),
                                onChanged: (v) => setState(() {
                                  if (v == true) {
                                    if (_tipo == 0) _selecionados.clear();
                                    _selecionados.add(a.id);
                                  } else {
                                    _selecionados.remove(a.id);
                                  }
                                }),
                              );
                            }).toList(),
                          ),
                  ),
                  if (_erro != null)
                    Text(_erro!, style: const TextStyle(color: Colors.red)),
                ],
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Salvar'),
        ),
      ],
    );
  }
}

// ============================ LANÇAR PONTOS ============================
class _PontosTab extends StatefulWidget {
  const _PontosTab();
  @override
  State<_PontosTab> createState() => _PontosTabState();
}

class _PontosTabState extends State<_PontosTab> {
  late final ApiClient api = context.read<ApiClient>();
  List<Modalidade> _modalidades = [];
  Modalidade? _modalidade;
  List<Competidor> _competidores = [];
  Competidor? _competidor;
  List<Lancamento> _historico = [];
  final _pontos = TextEditingController(text: '3');
  final _motivo = TextEditingController();
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pontos.dispose();
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _modalidades = await api.modalidades();
      _modalidade = _modalidades.isNotEmpty ? _modalidades.first : null;
      if (_modalidade != null) await _carregarDados();
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _carregarDados() async {
    if (_modalidade == null) return;
    _competidores = await api.competidores(_modalidade!.id);
    _competidor = _competidores.isNotEmpty ? _competidores.first : null;
    _historico = await api.lancamentos(_modalidade!.id);
    if (mounted) setState(() {});
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _lancar() async {
    final pts = int.tryParse(_pontos.text);
    if (_competidor == null || pts == null || _motivo.text.trim().isEmpty) {
      _msg('Preencha competidor, pontos e motivo.');
      return;
    }
    setState(() => _enviando = true);
    try {
      await api.lancarPontos(_competidor!.id, pts, _motivo.text.trim());
      _motivo.clear();
      await _carregarDados();
      _msg('Pontos lançados!');
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _enviando = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_modalidades.isEmpty) {
      return const Center(child: Text('Cadastre uma modalidade primeiro.'));
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lançar pontos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<Modalidade>(
                        initialValue: _modalidade,
                        decoration: const InputDecoration(labelText: 'Modalidade', isDense: true),
                        items: _modalidades
                            .map((m) => DropdownMenuItem(value: m, child: Text(m.nome)))
                            .toList(),
                        onChanged: (m) {
                          setState(() => _modalidade = m);
                          _carregarDados();
                        },
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: DropdownButtonFormField<Competidor>(
                        initialValue: _competidor,
                        decoration: const InputDecoration(labelText: 'Competidor', isDense: true),
                        items: _competidores
                            .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.nome} (${tipoCompetidorLabels[c.tipo]})',
                                    overflow: TextOverflow.ellipsis)))
                            .toList(),
                        onChanged: (c) => setState(() => _competidor = c),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _pontos,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Pontos', isDense: true),
                      ),
                    ),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _motivo,
                        decoration: const InputDecoration(
                            labelText: 'Motivo', hintText: 'Ex.: Venceu etapa', isDense: true),
                      ),
                    ),
                  ],
                ),
                if (_competidor?.tipo == 1) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Color(0xFF1B7A3D)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pontos lançados para um time também contam no ranking individual de cada integrante.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _enviando ? null : _lancar,
                    icon: const Icon(Icons.add_task),
                    label: const Text('Lançar'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Últimos lançamentos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_historico.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Nenhum lançamento ainda.'))
        else
          ..._historico.map((l) => Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (l.pontos >= 0 ? const Color(0xFF1B7A3D) : Colors.red)
                        .withValues(alpha: 0.12),
                    child: Text('${l.pontos >= 0 ? '+' : ''}${l.pontos}',
                        style: TextStyle(
                            color: l.pontos >= 0 ? const Color(0xFF1B7A3D) : Colors.red,
                            fontWeight: FontWeight.bold)),
                  ),
                  title: Text(l.competidorNome),
                  subtitle: Text('${l.motivo} • ${dataHora.format(l.data)}'),
                ),
              )),
      ],
    );
  }
}
