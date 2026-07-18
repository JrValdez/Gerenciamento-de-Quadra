import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import 'competicao/classificacao_view.dart';

/// Área do Aluno: acompanha a classificação da competição (somente leitura).
class AlunoShell extends StatelessWidget {
  const AlunoShell({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.logado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final usuario = auth.usuario!;

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.emoji_events),
          SizedBox(width: 8),
          Text('Competição'),
        ]),
        actions: [
          Center(child: Text(usuario.nomeCompleto)),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text('Ranking da temporada',
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              const Expanded(child: ClassificacaoView()),
            ],
          ),
        ),
      ),
    );
  }
}
