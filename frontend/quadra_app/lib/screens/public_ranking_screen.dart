import 'package:flutter/material.dart';

import 'competicao/classificacao_view.dart';

/// Página pública do ranking da competição (sem login).
class PublicRankingScreen extends StatelessWidget {
  const PublicRankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.emoji_events),
          SizedBox(width: 8),
          Text('Ranking da Competição'),
        ]),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
            icon: const Icon(Icons.sports_tennis),
            label: const Text('Reservar quadra'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Entrar'),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Classificação da temporada',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const Text('Acompanhe a pontuação por modalidade.'),
                  ],
                ),
              ),
              const Expanded(child: ClassificacaoView()),
            ],
          ),
        ),
      ),
    );
  }
}
