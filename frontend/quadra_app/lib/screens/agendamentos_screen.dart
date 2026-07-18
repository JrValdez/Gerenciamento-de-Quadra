import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class AgendamentosScreen extends StatefulWidget {
  const AgendamentosScreen({super.key});
  @override
  State<AgendamentosScreen> createState() => _AgendamentosScreenState();
}

class _AgendamentosScreenState extends State<AgendamentosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Agendamento> _itens = [];
  int? _filtroStatus;
  bool _carregando = true;

  static const _cores = [Colors.orange, Color(0xFF1B7A3D), Colors.blueGrey, Colors.red];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      final itens = await api.agendamentos(status: _filtroStatus);
      setState(() {
        _itens = itens;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
      _msg('Erro ao carregar: $e');
    }
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _mudarStatus(Agendamento a, int status) async {
    try {
      await api.alterarStatusAgendamento(a.id, status);
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            children: [
              const Text('Filtrar: '),
              const SizedBox(width: 8),
              _chip('Todos', null),
              for (var i = 0; i < statusAgendamentoLabels.length; i++)
                _chip(statusAgendamentoLabels[i], i),
              const Spacer(),
              IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh)),
            ],
          ),
        ),
        Expanded(
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _itens.isEmpty
                  ? const Center(child: Text('Nenhum agendamento.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _itens.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _card(_itens[i]),
                    ),
        ),
      ],
    );
  }

  Widget _chip(String label, int? status) {
    final sel = _filtroStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: sel,
        onSelected: (_) {
          setState(() => _filtroStatus = status);
          _carregar();
        },
      ),
    );
  }

  Widget _card(Agendamento a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 56, color: _cores[a.status]),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.nomeCliente, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('${a.telefoneCliente} • ${a.emailCliente}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.quadraNome),
                  Text('${dataFmt.format(a.inicio)}  ${horaFmt.format(a.inicio)}-${horaFmt.format(a.fim)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            Expanded(child: Text(moeda.format(a.valorTotal))),
            Chip(
              label: Text(a.statusLabel),
              backgroundColor: _cores[a.status].withValues(alpha: 0.15),
              labelStyle: TextStyle(color: _cores[a.status]),
              side: BorderSide.none,
            ),
            PopupMenuButton<int>(
              onSelected: (s) => _mudarStatus(a, s),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 1, child: Text('Confirmar')),
                const PopupMenuItem(value: 2, child: Text('Concluir')),
                const PopupMenuItem(value: 3, child: Text('Cancelar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
