import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import '../theme.dart';
import '../widgets/auth_redirect.dart';
import 'dashboard_screen.dart';
import 'agendamentos_screen.dart';
import 'quadras_screen.dart';
import 'produtos_screen.dart';
import 'cupons_screen.dart';
import 'caixa_screen.dart';
import 'usuarios_screen.dart';
import 'bloqueios_screen.dart';
import 'professores_screen.dart';
import 'reservar_aula_screen.dart';
import 'alunos_screen.dart';
import 'analise_screen.dart';
import 'competicao/competicao_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.logado) return const AuthRedirect(rota: '/login');
    final usuario = auth.usuario!;

    final paginas = <_NavItem>[
      if (usuario.isProfessor)
        const _NavItem(Icons.school, 'Reservar aula', ReservarAulaScreen()),
      if (usuario.isProfessor)
        const _NavItem(Icons.groups, 'Alunos', AlunosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.dashboard, 'Painel', DashboardScreen()),
      if (usuario.isInterno) const _NavItem(Icons.event_note, 'Agendamentos', AgendamentosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.event_busy, 'Bloqueios', BloqueiosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.stadium, 'Quadras', QuadrasScreen()),
      if (usuario.isInterno) const _NavItem(Icons.inventory_2, 'Produtos', ProdutosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.local_offer, 'Cupons', CuponsScreen()),
      if (usuario.isInterno) const _NavItem(Icons.point_of_sale, 'Caixa', CaixaScreen()),
      if (usuario.isInterno)
        const _NavItem(Icons.sports, 'Professores', ProfessoresScreen()),
      if (usuario.isGestorCompeticao)
        const _NavItem(Icons.emoji_events, 'Competição', CompeticaoScreen()),
      if (usuario.isInterno) const _NavItem(Icons.group, 'Usuários', UsuariosScreen()),
      if (usuario.isAdmin) const _NavItem(Icons.insights, 'Análises', AnaliseScreen()),
    ];
    if (paginas.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sem telas disponíveis para este papel.')));
    }
    if (_index >= paginas.length) _index = 0;

    // ----- Celular / tela estreita: AppBar + menu em gaveta (rola, cabe em telas baixas) -----
    if (isCompact(context)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(paginas[_index].label,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Brand.green,
                child: Text(
                  usuario.nomeCompleto.isNotEmpty
                      ? usuario.nomeCompleto[0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.sports_tennis, color: Brand.green, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(usuario.nomeCompleto,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text(usuario.papeis.join(', '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: [
                      for (var i = 0; i < paginas.length; i++)
                        ListTile(
                          leading: Icon(paginas[i].icon),
                          title: Text(paginas[i].label),
                          selected: i == _index,
                          selectedTileColor: Brand.greenSoft,
                          onTap: () {
                            setState(() => _index = i);
                            Navigator.pop(context);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () async {
                    await auth.logout();
                    if (context.mounted) Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
        ),
        body: paginas[_index].tela,
      );
    }

    // ----- Desktop / tela larga: NavigationRail lateral -----
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            extended: MediaQuery.of(context).size.width > 1100,
            minExtendedWidth: 200,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: const [
                  Icon(Icons.sports_tennis, color: Brand.green, size: 32),
                  SizedBox(height: 4),
                ],
              ),
            ),
            destinations: paginas
                .map((p) => NavigationRailDestination(
                      icon: Icon(p.icon),
                      label: Text(p.label),
                    ))
                .toList(),
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    tooltip: 'Sair',
                    icon: const Icon(Icons.logout),
                    onPressed: () async {
                      await auth.logout();
                      if (context.mounted) Navigator.pushReplacementNamed(context, '/');
                    },
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  alignment: Alignment.centerLeft,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final compacto = c.maxWidth < 520;
                      return Row(
                        children: [
                          Expanded(
                            child: Text(paginas[_index].label,
                                style: Theme.of(context).textTheme.titleLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 12),
                          if (!compacto) ...[
                            Flexible(
                              child: Text(usuario.nomeCompleto,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 8),
                          ],
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Brand.green,
                            child: Text(
                              usuario.nomeCompleto.isNotEmpty
                                  ? usuario.nomeCompleto[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                          if (!compacto) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(usuario.papeis.join(', ')),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
                const Divider(height: 1),
                Expanded(child: paginas[_index].tela),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget tela;
  const _NavItem(this.icon, this.label, this.tela);
}
