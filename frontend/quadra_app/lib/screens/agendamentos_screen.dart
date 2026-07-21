import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/phone_formatter.dart';

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

  static const _cores = [Colors.orange, Brand.green, Colors.blueGrey, Colors.red];

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
      _msg(mensagemErro(e));
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
      _msg(mensagemErro(e));
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
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Padding(padding: EdgeInsets.only(right: 2), child: Text('Filtrar:')),
                    _chip('Todos', null),
                    for (var i = 0; i < statusAgendamentoLabels.length; i++)
                      _chip(statusAgendamentoLabels[i], i),
                  ],
                ),
              ),
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
    return ChoiceChip(
      label: Text(label),
      selected: sel,
      onSelected: (_) {
        setState(() => _filtroStatus = status);
        _carregar();
      },
    );
  }

  Widget _card(Agendamento a) {
    final cor = _cores[a.status];
    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: cor,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(a.nomeCliente,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(a.statusLabel),
                          backgroundColor: cor.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: cor, fontWeight: FontWeight.w600),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        ),
                        PopupMenuButton<int>(
                          tooltip: 'Alterar status',
                          onSelected: (s) => _mudarStatus(a, s),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 1, child: Text('Confirmar')),
                            PopupMenuItem(value: 2, child: Text('Concluir')),
                            PopupMenuItem(value: 3, child: Text('Cancelar')),
                          ],
                        ),
                      ],
                    ),
                    if (a.telefoneCliente.isNotEmpty || a.emailCliente.isNotEmpty)
                      Text('${formatPhone(a.telefoneCliente)} • ${a.emailCliente}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 18,
                      runSpacing: 6,
                      children: [
                        _meta(Icons.stadium, a.quadraNome),
                        _meta(Icons.schedule,
                            '${dataFmt.format(a.inicio)}  ${horaFmt.format(a.inicio)}-${horaFmt.format(a.fim)}'),
                        _meta(
                          Icons.payments,
                          a.cupomCodigo != null && a.cupomCodigo!.isNotEmpty
                              ? '${moeda.format(a.valorTotal)}  (${a.cupomCodigo} -${moeda.format(a.valorDesconto)})'
                              : moeda.format(a.valorTotal),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meta(IconData icone, String texto) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icone, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 5),
        Text(texto, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
