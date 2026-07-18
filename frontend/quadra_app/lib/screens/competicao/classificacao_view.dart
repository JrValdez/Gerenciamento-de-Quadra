import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api_client.dart';
import '../../models.dart';

/// Visualização (somente leitura) da classificação por modalidade,
/// com filtro Individual/Equipe. Reutilizada na área do aluno e na gestão.
class ClassificacaoView extends StatefulWidget {
  const ClassificacaoView({super.key});
  @override
  State<ClassificacaoView> createState() => _ClassificacaoViewState();
}

class _ClassificacaoViewState extends State<ClassificacaoView> {
  late final ApiClient api = context.read<ApiClient>();
  List<Modalidade> _modalidades = [];
  Modalidade? _modalidade;
  int? _tipo; // null = todos, 0 individual, 1 equipe
  List<ClassificacaoItem> _itens = [];
  bool _carregandoMod = true;
  bool _carregandoRank = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarModalidades();
  }

  Future<void> _carregarModalidades() async {
    try {
      final m = await api.modalidades();
      setState(() {
        _modalidades = m;
        _modalidade = m.isNotEmpty ? m.first : null;
        _carregandoMod = false;
      });
      if (_modalidade != null) _carregarRanking();
    } catch (e) {
      setState(() {
        _erro = '$e';
        _carregandoMod = false;
      });
    }
  }

  Future<void> _carregarRanking() async {
    if (_modalidade == null) return;
    setState(() => _carregandoRank = true);
    try {
      final r = await api.classificacao(_modalidade!.id, tipo: _tipo);
      setState(() {
        _itens = r;
        _carregandoRank = false;
      });
    } catch (e) {
      setState(() {
        _itens = [];
        _carregandoRank = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregandoMod) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return Center(child: Text('Erro: $_erro'));
    if (_modalidades.isEmpty) {
      return const Center(child: Text('Nenhuma modalidade cadastrada ainda.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
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
                    _carregarRanking();
                  },
                ),
              ),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: -1, label: Text('Todos')),
                  ButtonSegment(value: 0, label: Text('Individual')),
                  ButtonSegment(value: 1, label: Text('Times')),
                ],
                selected: {_tipo ?? -1},
                onSelectionChanged: (s) {
                  final v = s.first;
                  setState(() => _tipo = v == -1 ? null : v);
                  _carregarRanking();
                },
              ),
              IconButton(onPressed: _carregarRanking, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: _carregandoRank
              ? const Center(child: CircularProgressIndicator())
              : _itens.isEmpty
                  ? const Center(child: Text('Nenhum competidor pontuado nesta modalidade.'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: _itens.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _linha(_itens[i]),
                    ),
        ),
      ],
    );
  }

  Widget _linha(ClassificacaoItem c) {
    final medalha = switch (c.posicao) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => Colors.transparent,
    };
    final top3 = c.posicao <= 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: top3 ? medalha : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(color: top3 ? medalha : Colors.grey.shade300),
              ),
              child: Text('${c.posicao}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: top3 ? Colors.black87 : Colors.grey.shade700,
                  )),
            ),
            const SizedBox(width: 16),
            Icon(c.tipo == 1 ? Icons.groups : Icons.person,
                color: const Color(0xFF1B7A3D), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  if (c.tipo == 1 && c.membros.isNotEmpty)
                    Text(c.membros.map((m) => m.alunoNome).join(' • '),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Text('${c.qtdLancamentos} evento(s)',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${c.totalPontos}',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1B7A3D))),
                const Text('pts', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
