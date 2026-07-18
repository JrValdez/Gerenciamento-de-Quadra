import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Usuario> _itens = [];
  bool _carregando = true;

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
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _UsuarioDialog(api: api),
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
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _itens.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u = _itens[i];
                final euId = context.read<AuthProvider>().usuario?.id;
                final souEu = u.id == euId;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF1B7A3D),
                      child: Text(
                        u.nomeCompleto.isNotEmpty ? u.nomeCompleto[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(u.nomeCompleto,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(u.email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...u.papeis.map((p) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Chip(
                                label: Text(p),
                                visualDensity: VisualDensity.compact,
                              ),
                            )),
                        const SizedBox(width: 8),
                        Text(u.ativo ? 'Ativo' : 'Inativo',
                            style: TextStyle(color: u.ativo ? const Color(0xFF1B7A3D) : Colors.grey)),
                        Switch(value: u.ativo, onChanged: souEu ? null : (_) => _toggle(u)),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: souEu ? 'Você não pode excluir a si mesmo' : 'Excluir usuário',
                          onPressed: souEu ? null : () => _excluir(u),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _UsuarioDialog extends StatefulWidget {
  final ApiClient api;
  const _UsuarioDialog({required this.api});
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
      title: const Text('Novo usuário'),
      content: SizedBox(
        width: 400,
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
                items: const [
                  DropdownMenuItem(value: 'Atendente', child: Text('Atendente')),
                  DropdownMenuItem(value: 'Professor', child: Text('Professor')),
                  DropdownMenuItem(value: 'Aluno', child: Text('Aluno')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'Cliente', child: Text('Cliente')),
                ],
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
