import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/async_view.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});
  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  final _ctrl = AsyncViewController();

  void _msg(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _editar([Produto? p]) async {
    final salvo = await showDialog<bool>(
      context: context,
      builder: (_) => _ProdutoDialog(api: api, produto: p),
    );
    if (salvo == true) _ctrl.reload();
  }

  Future<void> _vender(List<Produto> itens) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _VendaDialog(
        api: api,
        produtos: itens.where((p) => p.ativo).toList(),
      ),
    );
    if (ok == true) {
      _msg('Venda registrada e lançada no caixa!');
      _ctrl.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthProvider>().usuario?.isAdmin ?? false;
    return AsyncView<List<Produto>>(
      controlador: _ctrl,
      carregar: () => api.produtos(incluirInativos: true),
      mensagemErro: (_) =>
          'Não foi possível carregar os produtos. Tente novamente.',
      builder: (context, itens, recarregar) => Scaffold(
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'venda',
              onPressed: () => _vender(itens),
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: const Text('Venda rápida'),
            ),
            const SizedBox(height: 12),
            FloatingActionButton.extended(
              heroTag: 'novo',
              onPressed: () => _editar(),
              icon: const Icon(Icons.add),
              label: const Text('Novo produto'),
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 150),
          itemCount: itens.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _card(itens[i], isAdmin),
        ),
      ),
    );
  }

  Widget _card(Produto p, bool isAdmin) {
    final semEstoque = p.estoqueQuantidade <= 0;
    final info = Row(
      children: [
        CircleAvatar(
          backgroundColor: Brand.greenTint,
          child: Text(
            p.categoria.isNotEmpty ? p.categoria[0] : '?',
            style: const TextStyle(color: Brand.green),
          ),
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
                    child: Text(
                      p.nome,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!p.ativo)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Chip(
                        label: Text('Inativo'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${p.categoria} • Estoque: ${p.estoqueQuantidade}'
                '${semEstoque ? '  (sem estoque)' : ''}',
                style: TextStyle(
                  color: semEstoque ? Colors.red : Colors.grey.shade600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
    final acoes = <Widget>[
      Text(
        moeda.format(p.preco),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      IconButton(
        onPressed: () => _editar(p),
        icon: const Icon(Icons.edit),
        tooltip: 'Editar',
      ),
      if (isAdmin)
        IconButton(
          tooltip: 'Excluir',
          onPressed: () async {
            try {
              await api.excluirProduto(p.id);
              _ctrl.reload();
            } catch (e) {
              _msg('Erro: $e');
            }
          },
          icon: const Icon(Icons.delete_outline),
        ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: LayoutBuilder(
          builder: (context, c) {
            final acoesWrap = Wrap(
              spacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.end,
              children: acoes,
            );
            if (c.maxWidth < 460) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [info, const SizedBox(height: 6), acoesWrap],
              );
            }
            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 8),
                Flexible(child: acoesWrap),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProdutoDialog extends StatefulWidget {
  final ApiClient api;
  final Produto? produto;
  const _ProdutoDialog({required this.api, this.produto});
  @override
  State<_ProdutoDialog> createState() => _ProdutoDialogState();
}

class _ProdutoDialogState extends State<_ProdutoDialog> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.produto?.nome);
  late final _cat = TextEditingController(
    text: widget.produto?.categoria ?? 'Bebida',
  );
  late final _preco = TextEditingController(
    text: widget.produto?.preco.toStringAsFixed(2),
  );
  late final _estoque = TextEditingController(
    text: '${widget.produto?.estoqueQuantidade ?? 0}',
  );
  late final _desc = TextEditingController(text: widget.produto?.descricao);
  late bool _ativo = widget.produto?.ativo ?? true;
  bool _salvando = false;

  @override
  void dispose() {
    _nome.dispose();
    _cat.dispose();
    _preco.dispose();
    _estoque.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _salvando = true);
    final body = {
      'nome': _nome.text.trim(),
      'descricao': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'categoria': _cat.text.trim(),
      'preco': double.tryParse(_preco.text.replaceAll(',', '.')) ?? 0,
      'estoqueQuantidade': int.tryParse(_estoque.text) ?? 0,
      'ativo': _ativo,
    };
    try {
      if (widget.produto == null) {
        await widget.api.criarProduto(body);
      } else {
        await widget.api.atualizarProduto(widget.produto!.id, body);
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
      title: Text(widget.produto == null ? 'Novo produto' : 'Editar produto'),
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
                controller: _cat,
                decoration: const InputDecoration(labelText: 'Categoria'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _preco,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Preço',
                        prefixText: 'R\$ ',
                      ),
                      validator: (v) =>
                          (double.tryParse((v ?? '').replaceAll(',', '.')) ==
                              null)
                          ? 'Inválido'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _estoque,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Estoque'),
                      validator: (v) =>
                          (int.tryParse(v ?? '') == null) ? 'Inválido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _desc,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativo'),
                value: _ativo,
                onChanged: (v) => setState(() => _ativo = v),
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

class _VendaDialog extends StatefulWidget {
  final ApiClient api;
  final List<Produto> produtos;
  const _VendaDialog({required this.api, required this.produtos});
  @override
  State<_VendaDialog> createState() => _VendaDialogState();
}

class _VendaDialogState extends State<_VendaDialog> {
  final Map<String, int> _carrinho = {}; // produtoId -> qtd
  int _formaPagamento = 0;
  bool _enviando = false;
  String? _erro;

  double get _total {
    double t = 0;
    for (final p in widget.produtos) {
      final q = _carrinho[p.id] ?? 0;
      t += q * p.preco;
    }
    return t;
  }

  Future<void> _finalizar() async {
    final itens = _carrinho.entries.where((e) => e.value > 0).toList();
    if (itens.isEmpty) {
      setState(() => _erro = 'Adicione ao menos um item.');
      return;
    }
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.api.registrarVenda({
        'itens': itens
            .map((e) => {'produtoId': e.key, 'quantidade': e.value})
            .toList(),
        'formaPagamento': _formaPagamento,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _enviando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao registrar venda.';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Venda rápida'),
      content: SizedBox(
        width: dialogW(context, 460),
        height: dialogH(context, 460),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: widget.produtos.map((p) {
                  final q = _carrinho[p.id] ?? 0;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.nome),
                    subtitle: Text(
                      '${moeda.format(p.preco)} • estoque ${p.estoqueQuantidade}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: q > 0
                              ? () => setState(() => _carrinho[p.id] = q - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$q'),
                        IconButton(
                          onPressed: q < p.estoqueQuantidade
                              ? () => setState(() => _carrinho[p.id] = q + 1)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            Row(
              children: [
                const Text('Pagamento: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _formaPagamento,
                  items: [
                    for (var i = 0; i < formaPagamentoLabels.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(formaPagamentoLabels[i]),
                      ),
                  ],
                  onChanged: (v) => setState(() => _formaPagamento = v ?? 0),
                ),
                const Spacer(),
                Text(
                  'Total: ${moeda.format(_total)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (_erro != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_erro!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _finalizar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Finalizar venda'),
        ),
      ],
    );
  }
}
