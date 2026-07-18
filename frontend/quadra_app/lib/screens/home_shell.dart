import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth_provider.dart';
import 'dashboard_screen.dart';
import 'agendamentos_screen.dart';
import 'quadras_screen.dart';
import 'produtos_screen.dart';
import 'cupons_screen.dart';
import 'caixa_screen.dart';
import 'usuarios_screen.dart';
import 'bloqueios_screen.dart';
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
    if (!auth.logado) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final usuario = auth.usuario!;

    final paginas = <_NavItem>[
      if (usuario.isInterno) const _NavItem(Icons.dashboard, 'Painel', DashboardScreen()),
      if (usuario.isInterno) const _NavItem(Icons.event_note, 'Agendamentos', AgendamentosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.event_busy, 'Bloqueios', BloqueiosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.stadium, 'Quadras', QuadrasScreen()),
      if (usuario.isInterno) const _NavItem(Icons.inventory_2, 'Produtos', ProdutosScreen()),
      if (usuario.isInterno) const _NavItem(Icons.local_offer, 'Cupons', CuponsScreen()),
      if (usuario.isInterno) const _NavItem(Icons.point_of_sale, 'Caixa', CaixaScreen()),
      if (usuario.isGestorCompeticao)
        const _NavItem(Icons.emoji_events, 'Competição', CompeticaoScreen()),
      if (usuario.isAdmin) const _NavItem(Icons.group, 'Usuários', UsuariosScreen()),
    ];
    if (paginas.isEmpty) {
      return const Scaffold(body: Center(child: Text('Sem telas disponíveis para este papel.')));
    }
    if (_index >= paginas.length) _index = 0;

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
                  Icon(Icons.sports_tennis, color: Color(0xFF1B7A3D), size: 32),
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
                  child: Row(
                    children: [
                      Text(paginas[_index].label,
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Text(usuario.nomeCompleto),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF1B7A3D),
                        child: Text(
                          usuario.nomeCompleto.isNotEmpty
                              ? usuario.nomeCompleto[0].toUpperCase()
                              : '?',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(usuario.papeis.join(', ')),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
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
