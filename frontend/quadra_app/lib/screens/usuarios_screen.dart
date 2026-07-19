import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../theme.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Usuario> _itens = [];
  bool _carregando = true;

  /// Categoria selecionada no filtro (null = todas).
  String? _filtroCategoria;

  /// Categorias exibidas no filtro: a lista fixa do sistema mais qualquer
  /// papel presente nos usuários carregados que ainda não esteja nela.
  List<String> get _categoriasFiltro {
    final extras = _itens
        .expand((u) => u.papeis)
        .where((p) => !kCategoriasUsuario.contains(p))
        .toSet()
        .toList()
      ..sort();
    return [...kCategoriasUsuario, ...extras];
  }

  List<Usuario> get _itensFiltrados => _filtroCategoria == null
      ? _itens
      : _itens.where((u) => u.papeis.contains(_filtroCategoria)).toList();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens = await api.usuarios();
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _novo() async {
    final souAdmin = context.read<AuthProvider>().usuario?.isAdmin ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _UsuarioDialog(api: api, podeAtribuirAdmin: souAdmin),
    );
    if (ok == true) {
      _msg('Usuário criado!');
      _carregar();
    }
  }

  Future<void> _toggle(Usuario u) async {
    try {
      await api.definirAtivo(u.id, !u.ativo);
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  Future<void> _excluir(Usuario u) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text('Tem certeza que deseja excluir "${u.nomeCompleto}"? '
            'Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.excluirUsuario(u.id);
        _msg('Usuário excluído.');
        _carregar();
      } catch (e) {
        _msg('Erro: $e');
      }
    }
  }

  Future<void> _trocarPapel(Usuario u, String papel) async {
    if (u.papeis.length == 1 && u.papeis.first == papel) return;
    try {
      await api.definirPapel(u.id, papel);
      _msg('Classificação alterada para $papel.');
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  Future<void> _editar(Usuario u) async {
    final eu = context.read<AuthProvider>().usuario;
    final souEu = u.id == eu?.id;
    final souAdmin = eu?.isAdmin ?? false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _EditarUsuarioDialog(
          api: api, usuario: u, podeMudarPapel: !souEu, podeAtribuirAdmin: souAdmin),
    );
    if (ok == true) {
      _msg('Dados atualizados!');
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo usuário'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _barraFiltro(),
                Expanded(child: _lista()),
              ],
            ),
    );
  }

  Widget _barraFiltro() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Todos'),
              selected: _filtroCategoria == null,
              onSelected: (_) => setState(() => _filtroCategoria = null),
            ),
            ..._categoriasFiltro.map((c) => FilterChip(
                  label: Text(c),
                  selected: _filtroCategoria == c,
                  onSelected: (sel) =>
                      setState(() => _filtroCategoria = sel ? c : null),
                )),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    final itens = _itensFiltrados;
    if (itens.isEmpty) {
      return const Center(child: Text('Nenhum usuário nesta categoria.'));
    }
    return ListView.separated(
      // padding inferior extra para o último card não ficar atrás do botão "Novo usuário".
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
      itemCount: itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final u = itens[i];
        final eu = context.read<AuthProvider>().usuario;
        final souEu = u.id == eu?.id;
        final souAdmin = eu?.isAdmin ?? false;
        // Atendente não pode mexer em contas de administrador.
        final protegido = !souAdmin && u.isAdmin;
        final bloqueado = souEu || protegido;
        final papeisMenu =
            souAdmin ? kCategoriasUsuario : kCategoriasUsuario.where((c) => c != 'Admin').toList();
        final papelControl = bloqueado
            ? Wrap(
                spacing: 6,
                children: (u.papeis.isEmpty ? const ['—'] : u.papeis)
                    .map((p) => Chip(label: Text(p), visualDensity: VisualDensity.compact))
                    .toList(),
              )
            : PopupMenuButton<String>(
                tooltip: 'Trocar classificação',
                onSelected: (papel) => _trocarPapel(u, papel),
                itemBuilder: (_) => papeisMenu
                    .map((c) => PopupMenuItem(
                          value: c,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (u.papeis.contains(c))
                                const Icon(Icons.check, size: 16, color: Color(0xFF1B7A3D))
                              else
                                const SizedBox(width: 16),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          ),
                        ))
                    .toList(),
                child: Chip(
                  avatar: const Icon(Icons.swap_horiz, size: 16),
                  label: Text(u.papeis.isNotEmpty ? u.papeis.join(', ') : 'Sem papel'),
                  visualDensity: VisualDensity.compact,
                ),
              );

        final acoes = <Widget>[
          papelControl,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(u.ativo ? Icons.check_circle : Icons.cancel,
                  size: 15, color: u.ativo ? const Color(0xFF1B7A3D) : Colors.grey),
              const SizedBox(width: 4),
              Text(u.ativo ? 'Ativo' : 'Inativo',
                  style: TextStyle(color: u.ativo ? const Color(0xFF1B7A3D) : Colors.grey)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: protegido
                ? 'Atendente não pode alterar administradores'
                : 'Editar dados / papel',
            onPressed: protegido ? null : () => _editar(u),
          ),
          Switch(value: u.ativo, onChanged: bloqueado ? null : (_) => _toggle(u)),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: souEu
                ? 'Você não pode excluir a si mesmo'
                : protegido
                    ? 'Atendente não pode alterar administradores'
                    : 'Excluir usuário',
            onPressed: bloqueado ? null : () => _excluir(u),
          ),
        ];

        final info = Row(
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF1B7A3D),
              child: Text(
                u.nomeCompleto.isNotEmpty ? u.nomeCompleto[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(u.nomeCompleto,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(u.email,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (u.telefone.isNotEmpty)
                    Text(u.telefone,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: LayoutBuilder(
              builder: (context, c) {
                final acoesWrap = Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: acoes,
                );
                if (c.maxWidth < 640) {
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
      },
    );
  }
}

class _UsuarioDialog extends StatefulWidget {
  final ApiClient api;
  final bool podeAtribuirAdmin;
  const _UsuarioDialog({required this.api, required this.podeAtribuirAdmin});
  @override
  State<_UsuarioDialog> createState() => _UsuarioDialogState();
}

class _UsuarioDialogState extends State<_UsuarioDialog> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  String _papel = 'Atendente';
  bool _salvando = false;

  List<String> get _opcoesPapel => widget.podeAtribuirAdmin
      ? kCategoriasUsuario
      : kCategoriasUsuario.where((c) => c != 'Admin').toList();
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.registrar(_nome.text.trim(), _email.text.trim(), _senha.text, _papel);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _salvando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao criar usuário.';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Novo usuário'),
      content: SizedBox(
        width: dialogW(context, 488),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha (mín. 6)'),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _papel,
                decoration: const InputDecoration(labelText: 'Papel'),
                items: _opcoesPapel
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _papel = v ?? 'Atendente'),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
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
              : const Text('Criar'),
        ),
      ],
    );
  }
}

class _EditarUsuarioDialog extends StatefulWidget {
  final ApiClient api;
  final Usuario usuario;
  final bool podeMudarPapel;
  final bool podeAtribuirAdmin;
  const _EditarUsuarioDialog(
      {required this.api,
      required this.usuario,
      required this.podeMudarPapel,
      required this.podeAtribuirAdmin});
  @override
  State<_EditarUsuarioDialog> createState() => _EditarUsuarioDialogState();
}

class _EditarUsuarioDialogState extends State<_EditarUsuarioDialog> {
  final _form = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.usuario.nomeCompleto);
  late final _email = TextEditingController(text: widget.usuario.email);
  late final _telefone = TextEditingController(text: widget.usuario.telefone);
  late final String _papelOriginal =
      widget.usuario.papeis.isNotEmpty ? widget.usuario.papeis.first : kCategoriasUsuario.first;
  late String _papel = _papelOriginal;
  bool _salvando = false;
  String? _erro;

  List<String> get _opcoesPapel => widget.podeAtribuirAdmin
      ? kCategoriasUsuario
      : kCategoriasUsuario.where((c) => c != 'Admin').toList();

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.editarUsuario(
          widget.usuario.id, _nome.text.trim(), _email.text.trim(), _telefone.text.trim());
      if (widget.podeMudarPapel && _papel != _papelOriginal) {
        await widget.api.definirPapel(widget.usuario.id, _papel);
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
      scrollable: true,
      title: const Text('Editar usuário'),
      content: SizedBox(
        width: dialogW(context, 488),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone / WhatsApp'),
              ),
              const SizedBox(height: 12),
              if (widget.podeMudarPapel)
                DropdownButtonFormField<String>(
                  initialValue: _opcoesPapel.contains(_papel) ? _papel : null,
                  decoration: const InputDecoration(labelText: 'Papel / classificação'),
                  items: _opcoesPapel
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _papel = v ?? _papel),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Papel: ${widget.usuario.papeis.join(', ')}',
                      style: const TextStyle(color: Colors.grey)),
                ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
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
