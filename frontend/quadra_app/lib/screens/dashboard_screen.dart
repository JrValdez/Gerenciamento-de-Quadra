import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/async_view.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiClient>();
    return AsyncView<DashboardResumo>(
      carregar: api.dashboard,
      mensagemErro: (_) =>
          'Não foi possível carregar o resumo de hoje. Tente novamente.',
      builder: (context, r, recarregar) => RefreshIndicator(
        onRefresh: recarregar,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                Text(
                  'Resumo de hoje',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: recarregar,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _kpi(
                  'Reservas hoje',
                  '${r.agendamentosHoje}',
                  Icons.event,
                  Brand.green,
                ),
                _kpi(
                  'Pendentes',
                  '${r.agendamentosPendentes}',
                  Icons.hourglass_bottom,
                  Colors.orange,
                ),
                _kpi(
                  'Faturamento hoje',
                  moeda.format(r.faturamentoHoje),
                  Icons.attach_money,
                  Colors.indigo,
                ),
                _kpi(
                  r.caixaAberto ? 'Caixa (saldo)' : 'Caixa',
                  r.caixaAberto ? moeda.format(r.saldoCaixa ?? 0) : 'Fechado',
                  Icons.point_of_sale,
                  r.caixaAberto ? Colors.teal : Colors.grey,
                ),
                _kpi(
                  'Baixo estoque',
                  '${r.produtosBaixoEstoque}',
                  Icons.warning_amber,
                  r.produtosBaixoEstoque > 0 ? Colors.red : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Próximos agendamentos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (r.proximosAgendamentos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhum agendamento futuro.'),
                ),
              )
            else
              ...r.proximosAgendamentos.map(
                (a) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Brand.greenTint,
                      child: Icon(Icons.event_available, color: Brand.green),
                    ),
                    title: Text('${a.nomeCliente} • ${a.quadraNome}'),
                    subtitle: Text(
                      '${dataFmt.format(a.inicio)}  ${horaFmt.format(a.inicio)}-${horaFmt.format(a.fim)}  •  ${a.statusLabel}',
                    ),
                    trailing: Text(
                      moeda.format(a.valorTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: cor, size: 22),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
