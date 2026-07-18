import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../theme.dart';

class CuponsScreen extends StatefulWidget {
  const CuponsScreen({super.key});
  @override
  State<CuponsScreen> createState() => _CuponsScreenState();
}

class _CuponsScreenState extends State<CuponsScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Cupom> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens = await api.cupons(incluirInativos: true);
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _editar([Cupom? c]) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _CupomDialog(api: api, cupom: c),
    );
    if (salvo == true) _carregar();
  }

  String _descontoLabel(Cupom c) => c.tipo == 0
      ? '${c.valor.toStringAsFixed(c.valor.truncateToDouble() == c.valor ? 0 : 2)}% de desconto'
      : '${moeda.format(c.valor)} de desconto';

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().usuario?.isAdmin ?? false;
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editar(),
        icon: const Icon(Icons.add),
        label: const Text('Novo cupom'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Cupons de desconto criados pela equipe. Cada cupom tem um prazo '
                      'de validade — após a data ele deixa de ser válido.',
                    ),
                  ),
                ),
                Expanded(
                  child: _itens.isEmpty
                      ? const Center(child: Text('Nenhum cupom cadastrado.'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                          itemCount: _itens.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_itens[i], isAdmin),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _card(Cupom c, bool isAdmin) {
    final expirado = !c.valido;
    final temDesc = c.descricao != null && c.descricao!.isNotEmpty;
    final info = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: c.valido ? const Color(0xFFE6F4EA) : const Color(0xFFFDE7E7),
          child: Icon(Icons.local_offer, color: c.valido ? const Color(0xFF1B7A3D) : Colors.red),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(c.codigo,
                        style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  if (!c.ativo)
                    const Chip(label: Text('Inativo'), visualDensity: VisualDensity.compact)
                  else if (expirado)
                    const Chip(
                      label: Text('Expirado'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Color(0xFFFDE7E7),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text('${_descontoLabel(c)} • válido até ${dataFmt.format(c.validoAte)}',
                  style: TextStyle(color: expirado ? Colors.red : Colors.grey.shade700, fontSize: 13)),
              if (temDesc)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(c.descricao!,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ),
            ],
          ),
        ),
      ],
    );
    final acoes = <Widget>[
      IconButton(onPressed: () => _editar(c), icon: const Icon(Icons.edit), tooltip: 'Editar'),
      if (isAdmin)
        IconButton(
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            try {
              await api.excluirCupom(c.id);
              _carregar();
            } catch (e) {
              _msg('Erro: $e');
            }
          },
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: info),
            const SizedBox(width: 4),
            ...acoes,
          ],
        ),
      ),
    );
  }
}

class _CupomDialog extends StatefulWidget {
  final ApiClient api;
  final Cupom? cupom;
  const _CupomDialog({required this.api, this.cupom});
  @override
  State<_CupomDialog> createState() => _CupomDialogState();
}

class _CupomDialogState extends State<_CupomDialog> {
  final _form = GlobalKey<FormState>();
  late final _codigo = TextEditingController(text: widget.cupom?.codigo);
  late final _desc = TextEditingController(text: widget.cupom?.descricao);
  late final _valor = TextEditingController(
      text: widget.cupom == null ? '' : widget.cupom!.valor.toStringAsFixed(2));
  late int _tipo = widget.cupom?.tipo ?? 0;
  late DateTime _validoAte =
      widget.cupom?.validoAte ?? DateTime.now().add(const Duration(days: 30));
  late bool _ativo = widget.cupom?.ativo ?? true;
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _codigo.dispose();
    _desc.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _validoAte.isBefore(DateTime.now()) ? DateTime.now() : _validoAte,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _validoAte = d);
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    final valor = double.tryParse(_valor.text.replaceAll(',', '.')) ?? 0;
    if (_tipo == 0 && valor > 100) {
      setState(() => _erro = 'Desconto percentual não pode passar de 100%.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    // Valade até o fim do dia escolhido.
    final validoAte = DateTime(_validoAte.year, _validoAte.month, _validoAte.day, 23, 59, 59);
    final body = {
      'codigo': _codigo.text.trim().toUpperCase(),
      'descricao': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'tipo': _tipo,
      'valor': valor,
      'validoAte': validoAte.toUtc().toIso8601String(),
      'ativo': _ativo,
    };
    try {
      if (widget.cupom == null) {
        await widget.api.criarCupom(body);
      } else {
        await widget.api.atualizarCupom(widget.cupom!.id, body);
      }
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
      title: Text(widget.cupom == null ? 'Novo cupom' : 'Editar cupom'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _codigo,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                    labelText: 'Código', hintText: 'Ex.: VERAO10'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _tipo,
                      decoration: const InputDecoration(labelText: 'Tipo'),
                      items: [
                        for (var i = 0; i < tipoDescontoLabels.length; i++)
                          DropdownMenuItem(value: i, child: Text(tipoDescontoLabels[i])),
                      ],
                      onChanged: (v) => setState(() => _tipo = v ?? 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _valor,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Valor',
                        prefixText: _tipo == 1 ? 'R\$ ' : null,
                        suffixText: _tipo == 0 ? '%' : null,
                      ),
                      validator: (v) {
                        final d = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (d == null || d <= 0) return 'Inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _escolherData,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Válido até'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dataFmt.format(_validoAte)),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descrição (opcional)'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
              ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                ),
            ],
          ),
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
