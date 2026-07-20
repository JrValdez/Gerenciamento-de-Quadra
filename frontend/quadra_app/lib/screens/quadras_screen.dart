import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/async_view.dart';

class QuadrasScreen extends StatefulWidget {
  const QuadrasScreen({super.key});
  @override
  State<QuadrasScreen> createState() => _QuadrasScreenState();
}

class _QuadrasScreenState extends State<QuadrasScreen> {
  late final ApiClient api = context.read<ApiClient>();
  final _ctrl = AsyncViewController();

  void _msg(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _editar([Quadra? q]) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _QuadraDialog(api: api, quadra: q),
    );
    if (salvo == true) _ctrl.reload();
  }

  Future<void> _excluir(Quadra q) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir quadra'),
        content: Text(
          'Remover "${q.nome}"? Se houver agendamentos, ela será apenas inativada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.excluirQuadra(q.id);
        _ctrl.reload();
      } catch (e) {
        _msg('Erro: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().usuario?.isAdmin ?? false;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('Nova quadra'),
      ),
      body: AsyncView<List<Quadra>>(
        controlador: _ctrl,
        carregar: () => api.quadras(incluirInativas: true),
        mensagemErro: (_) =>
            'Não foi possível carregar as quadras. Tente novamente.',
        builder: (context, itens, recarregar) => GridView.extent(
          padding: const EdgeInsets.all(16),
          maxCrossAxisExtent: 440,
          childAspectRatio: 1.8,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: itens.map((q) => _card(q, isAdmin)).toList(),
        ),
      ),
    );
  }

  Widget _card(Quadra q, bool isAdmin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.stadium, color: Brand.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    q.nome,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!q.ativa)
                  const Chip(
                    label: Text('Inativa'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${q.horaAbertura.toString().padLeft(2, '0')}:00 às ${q.horaFechamento.toString().padLeft(2, '0')}:00',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: moeda.format(q.precoHora),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' / hora'),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => _editar(q),
                  icon: const Icon(Icons.edit),
                ),
                if (isAdmin)
                  IconButton(
                    onPressed: () => _excluir(q),
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuadraDialog extends StatefulWidget {
  final ApiClient api;
  final Quadra? quadra;
  const _QuadraDialog({required this.api, this.quadra});
  @override
  State<_QuadraDialog> createState() => _QuadraDialogState();
}

class _QuadraDialogState extends State<_QuadraDialog> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.quadra?.nome);
  late final _preco = TextEditingController(
    text: widget.quadra?.precoHora.toStringAsFixed(2),
  );
  late final _obs = TextEditingController(text: widget.quadra?.observacoes);
  late bool _ativa = widget.quadra?.ativa ?? true;
  late int _abertura = widget.quadra?.horaAbertura ?? 8;
  late int _fechamento = widget.quadra?.horaFechamento ?? 22;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    _obs.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    if (_fechamento <= _abertura) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fechamento deve ser depois da abertura.'),
        ),
      );
      return;
    }
    setState(() => _salvando = true);
    final body = {
      'nome': _nome.text.trim(),
      'precoHora': double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
      'horaAbertura': _abertura,
      'horaFechamento': _fechamento,
      'ativa': _ativa,
      'observacoes': _obs.text.trim().isEmpty ? null : _obs.text.trim(),
    };
    try {
      if (widget.quadra == null) {
        await widget.api.criarQuadra(body);
      } else {
        await widget.api.atualizarQuadra(widget.quadra!.id, body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _salvando = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.quadra == null ? 'Nova quadra' : 'Editar quadra'),
      content: SizedBox(
        width: dialogW(context, 488),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _preco,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Preço por hora',
                  prefixText: 'R\$ ',
                ),
                validator: (v) =>
                    (double.tryParse((v ?? '').replaceAll(',', '.')) == null)
                    ? 'Valor inválido'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _abertura,
                      decoration: const InputDecoration(labelText: 'Abre às'),
                      items: [
                        for (var h = 0; h <= 23; h++)
                          DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _abertura = v ?? 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _fechamento,
                      decoration: const InputDecoration(labelText: 'Fecha às'),
                      items: [
                        for (var h = 1; h <= 24; h++)
                          DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}:00'),
                          ),
                      ],
                      onChanged: (v) => setState(() => _fechamento = v ?? 22),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _obs,
                decoration: const InputDecoration(labelText: 'Observações'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativa'),
                value: _ativa,
                onChanged: (v) => setState(() => _ativa = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
