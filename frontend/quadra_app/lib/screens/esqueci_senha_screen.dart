import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';

/// Tela pública: informa o e-mail para receber o link de redefinição de senha.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});
  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _enviando = false;
  bool _enviado = false;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await context.read<ApiClient>().esqueciSenha(_email.text.trim());
      setState(() => _enviado = true);
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } catch (_) {
      setState(() => _erro = 'Falha ao conectar. A API está no ar?');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Esqueci minha senha')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: _enviado ? _sucesso(context) : _formulario(context),
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
          const Icon(Icons.lock_reset, size: 48, color: Color(0xFF1B7A3D)),
          const SizedBox(height: 12),
          Text('Recuperar senha', textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Informe seu e-mail. Se estiver cadastrado, enviaremos um link para você criar uma nova senha.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _email,
            decoration: const InputDecoration(labelText: 'E-mail'),
            keyboardType: TextInputType.emailAddress,
            onFieldSubmitted: (_) => _enviar(),
            validator: (v) => (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
          ),
          if (_erro != null) ...[
            const SizedBox(height: 14),
            Text(_erro!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Enviar link'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: const Text('Voltar para o login'),
          ),
        ],
      ),
    );
  }

  Widget _sucesso(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.mark_email_read, size: 48, color: Color(0xFF1B7A3D)),
        const SizedBox(height: 12),
        Text('Verifique seu e-mail', textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text(
          'Se o e-mail estiver cadastrado, enviamos um link de redefinição. '
          'Confira também a caixa de spam.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          child: const Text('Voltar para o login'),
        ),
      ],
    );
  }
}
