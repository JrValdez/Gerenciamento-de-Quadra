import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ApiClient api = context.read<ApiClient>();
  DashboardResumo? _resumo;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final r = await api.dashboard();
      setState(() {
        _resumo = r;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = '$e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(child: Text('Erro ao carregar: $_erro'));
    }
    final r = _resumo!;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Resumo de hoje', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _kpi('Reservas hoje', '${r.agendamentosHoje}', Icons.event, const Color(0xFF1B7A3D)),
              _kpi('Pendentes', '${r.agendamentosPendentes}', Icons.hourglass_bottom, Colors.orange),
              _kpi('Faturamento hoje', moeda.format(r.faturamentoHoje), Icons.attach_money, Colors.indigo),
              _kpi(
                r.caixaAberto ? 'Caixa (saldo)' : 'Caixa',
                r.caixaAberto ? moeda.format(r.saldoCaixa ?? 0) : 'Fechado',
                Icons.point_of_sale,
                r.caixaAberto ? Colors.teal : Colors.grey,
              ),
              _kpi('Baixo estoque', '${r.produtosBaixoEstoque}', Icons.warning_amber,
                  r.produtosBaixoEstoque > 0 ? Colors.red : Colors.grey),
            ],
          ),
          const SizedBox(height: 32),
          Text('Próximos agendamentos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          if (r.proximosAgendamentos.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhum agendamento futuro.'),
              ),
            )
          else
            ...r.proximosAgendamentos.map((a) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE6F4EA),
                      child: Icon(Icons.event_available, color: Color(0xFF1B7A3D)),
                    ),
                    title: Text('${a.nomeCliente} • ${a.quadraNome}'),
                    subtitle: Text(
                        '${dataFmt.format(a.inicio)}  ${horaFmt.format(a.inicio)}-${horaFmt.format(a.fim)}  •  ${a.statusLabel}'),
                    trailing: Text(moeda.format(a.valorTotal),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _kpi(String label, String valor, IconData icon, Color cor) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: cor, size: 22),
                ),
                const Spacer(),
              ]),
              const SizedBox(height: 14),
              Text(valor, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
