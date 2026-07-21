import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/phone_formatter.dart';
import '../widgets/async_view.dart';

/// Tela do professor: cadastrar e consultar alunos (papel Aluno).
class AlunosScreen extends StatefulWidget {
  const AlunosScreen({super.key});
  @override
  State<AlunosScreen> createState() => _AlunosScreenState();
}

class _AlunosScreenState extends State<AlunosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  final _ctrl = AsyncViewController();

  void _msg(String m) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    }
  }

  Future<void> _novo() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _AlunoDialog(api: api),
    );
    if (ok == true) {
      _msg('Aluno cadastrado!');
      _ctrl.reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.person_add),
        label: const Text('Novo aluno'),
      ),
      body: AsyncView<List<AlunoRef>>(
        controlador: _ctrl,
        carregar: api.alunos,
        mensagemErro: (_) =>
            'Não foi possível carregar os alunos. Tente novamente.',
        builder: (context, itens, recarregar) => itens.isEmpty
            ? const Center(
                child: Text(
                  'Nenhum aluno cadastrado.\nToque em "Novo aluno".',
                  textAlign: TextAlign.center,
                ),
              )
            : ListView.separated(
                // espaço no fim para o último card não ficar atrás do botão "Novo aluno".
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                itemCount: itens.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final a = itens[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Brand.green,
                        child: Text(
                          a.nome.isNotEmpty ? a.nome[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(
                        a.nome,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        a.telefone.isNotEmpty
                            ? '${a.email} • ${formatPhone(a.telefone)}'
                            : a.email,
                      ),
                      trailing: const Chip(
                        label: Text('Aluno'),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _AlunoDialog extends StatefulWidget {
  final ApiClient api;
  const _AlunoDialog({required this.api});
  @override
  State<_AlunoDialog> createState() => _AlunoDialogState();
}

class _AlunoDialogState extends State<_AlunoDialog> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _senha = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
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
      await widget.api.criarAluno(
        _nome.text.trim(),
        _email.text.trim(),
        _telefone.text.trim(),
        _senha.text,
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _salvando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao cadastrar aluno.';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Novo aluno'),
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
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'Telefone / WhatsApp',
                ),
                validator: (v) => (v == null || v.replaceAll(RegExp(r'[^\d]'), '').length < 10)
                    ? 'Telefone inválido'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _senha,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha (mín. 6)'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
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
              : const Text('Cadastrar'),
        ),
      ],
    );
  }
}
