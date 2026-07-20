import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class CaixaScreen extends StatefulWidget {
  const CaixaScreen({super.key});
  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _CaixaScreenState extends State<CaixaScreen> {
  late final ApiClient api = context.read<ApiClient>();
  Caixa? _caixa;
  List<Movimentacao> _movs = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _caixa = await api.caixaAtual();
      _movs = _caixa != null ? await api.movimentacoes(_caixa!.id) : [];
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _abrir() async {
    final v = await _pedirValor('Abrir caixa', 'Valor de abertura (troco inicial)');
    if (v == null) return;
    try {
      await api.abrirCaixa(v);
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  Future<void> _fechar() async {
    final v = await _pedirValor('Fechar caixa', 'Valor contado em caixa');
    if (v == null) return;
    try {
      final c = await api.fecharCaixa(v);
      final dif = v - c.saldoEsperado;
      _msg('Caixa fechado. Diferença: ${moeda.format(dif)}');
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  Future<void> _movimentar(int tipo) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _MovDialog(tipo: tipo),
    );
    if (r == null) return;
    try {
      await api.lancarMovimentacao(r);
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  Future<double?> _pedirValor(String titulo, String label) async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: label, prefixText: 'R\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              Navigator.pop(context, v);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_caixa == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nenhum caixa aberto.'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _abrir,
              icon: const Icon(Icons.lock_open),
              label: const Text('Abrir caixa'),
            ),
          ],
        ),
      );
    }

    final c = _caixa!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        LayoutBuilder(
          builder: (context, cst) {
            final w = cst.maxWidth;
            final cardW = w < 520 ? (w - 12) / 2 : (w - 36) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _kpi('Abertura', moeda.format(c.valorAbertura), Icons.play_circle, Colors.blueGrey, cardW),
                _kpi('Entradas', moeda.format(c.totalEntradas), Icons.arrow_downward,
                    Brand.green, cardW),
                _kpi('Saídas', moeda.format(c.totalSaidas), Icons.arrow_upward, Colors.red, cardW),
                _kpi('Saldo esperado', moeda.format(c.saldoEsperado),
                    Icons.account_balance_wallet, Colors.indigo, cardW),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _movimentar(0),
              icon: const Icon(Icons.add),
              label: const Text('Suprimento (entrada)'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _movimentar(1),
              icon: const Icon(Icons.remove),
              label: const Text('Sangria (saída)'),
            ),
            OutlinedButton.icon(
              onPressed: _fechar,
              icon: const Icon(Icons.lock),
              label: const Text('Fechar caixa'),
            ),
            Text('Aberto em ${dataHora.format(c.abertoEm)}',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Movimentações', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_movs.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('Sem movimentações ainda.'))
        else
          ..._movs.map(_movTile),
      ],
    );
  }

  Widget _kpi(String label, String valor, IconData icon, Color cor, double largura) {
    return SizedBox(
      width: largura,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: cor, size: 20),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(label,
                      style: TextStyle(color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(valor, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _movTile(Movimentacao m) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (m.entrada ? Brand.green : Colors.red).withValues(alpha: 0.12),
          child: Icon(m.entrada ? Icons.arrow_downward : Icons.arrow_upward,
              color: m.entrada ? Brand.green : Colors.red),
        ),
        title: Text(m.descricao),
        subtitle: Text('${m.categoria} • ${formaPagamentoLabels[m.formaPagamento]} • ${dataHora.format(m.criadoEm)}'),
        trailing: Text(
          '${m.entrada ? '+' : '-'} ${moeda.format(m.valor)}',
          style: TextStyle(
            color: m.entrada ? Brand.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _MovDialog extends StatefulWidget {
  final int tipo; // 0 entrada, 1 saida
  const _MovDialog({required this.tipo});
  @override
  State<_MovDialog> createState() => _MovDialogState();
}

class _MovDialogState extends State<_MovDialog> {
  final _valor = TextEditingController();
  final _desc = TextEditingController();
  int _forma = 0;

  @override
  void dispose() {
    _valor.dispose();
    _desc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrada = widget.tipo == 0;
    return AlertDialog(
      scrollable: true,
      title: Text(entrada ? 'Suprimento (entrada)' : 'Sangria (saída)'),
      content: SizedBox(
        width: dialogW(context, 448),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valor,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Valor', prefixText: 'R\$ '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _desc,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Pagamento: '),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _forma,
                items: [
                  for (var i = 0; i < formaPagamentoLabels.length; i++)
                    DropdownMenuItem(value: i, child: Text(formaPagamentoLabels[i])),
                ],
                onChanged: (v) => setState(() => _forma = v ?? 0),
              ),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(_valor.text.replaceAll(',', '.'));
            if (v == null || v <= 0 || _desc.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'tipo': widget.tipo,
              'categoria': entrada ? 'Suprimento' : 'Sangria',
              'valor': v,
              'descricao': _desc.text.trim(),
              'formaPagamento': _forma,
            });
          },
          child: const Text('Lançar'),
        ),
      ],
    );
  }
}
