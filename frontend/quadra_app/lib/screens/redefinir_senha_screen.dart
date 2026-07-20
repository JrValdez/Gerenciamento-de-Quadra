import 'package:flutter/material.dart';

import '../theme.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';

/// Tela aberta pelo link do e-mail: define a nova senha usando o token da URL.
class RedefinirSenhaScreen extends StatefulWidget {
  final String email;
  final String token;
  const RedefinirSenhaScreen({super.key, required this.email, required this.token});

  @override
  State<RedefinirSenhaScreen> createState() => _RedefinirSenhaScreenState();
}

class _RedefinirSenhaScreenState extends State<RedefinirSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _senha = TextEditingController();
  final _confirma = TextEditingController();
  bool _salvando = false;
  String? _erro;

  bool get _linkValido => widget.email.isNotEmpty && widget.token.isNotEmpty;

  @override
  void dispose() {
    _senha.dispose();
    _confirma.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await context.read<ApiClient>().redefinirSenha(widget.email, widget.token, _senha.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Senha redefinida! Entre com a nova senha.'),
            backgroundColor: Brand.green),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Falha ao conectar. A API está no ar?');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova senha')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _linkValido ? _formulario(context) : _linkInvalido(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formulario(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.password, size: 48, color: Brand.green),
          const SizedBox(height: 12),
          Text('Criar nova senha', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Redefinindo a senha de ${widget.email}', textAlign: TextAlign.center),
          const SizedBox(height: 20),
          TextFormField(
            controller: _senha,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Nova senha'),
            validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirma,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Confirmar senha'),
            onFieldSubmitted: (_) => _salvar(),
            validator: (v) => (v != _senha.text) ? 'As senhas não conferem' : null,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 14),
            Text(_erro!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _salvando ? null : _salvar,
            child: _salvando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Salvar nova senha'),
          ),
        ],
      ),
    );
  }

  Widget _linkInvalido(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.link_off, size: 48, color: Colors.redAccent),
        const SizedBox(height: 12),
        Text('Link inválido', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Este link de redefinição está incompleto ou expirou. Solicite um novo.',
            textAlign: TextAlign.center),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/esqueci-senha'),
          child: const Text('Solicitar novo link'),
        ),
      ],
    );
  }
}
