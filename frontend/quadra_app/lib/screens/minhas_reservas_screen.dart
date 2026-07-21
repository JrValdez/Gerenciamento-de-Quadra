import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../auth_provider.dart';
import '../models.dart';
import '../theme.dart';

class MinhasReservasScreen extends StatefulWidget {
  const MinhasReservasScreen({super.key});

  @override
  State<MinhasReservasScreen> createState() => _MinhasReservasScreenState();
}

class _MinhasReservasScreenState extends State<MinhasReservasScreen> {
  final ApiClient api = ApiClient(); // will be overridden by provider
  List<Agendamento> _reservas = [];
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
      final api = context.read<ApiClient>();
      final r = await api.minhasReservas();
      setState(() {
        _reservas = r;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = mensagemErro(e, 'Erro ao carregar reservas.');
        _carregando = false;
      });
    }
  }

  Future<void> _cancelar(Agendamento a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancelar reserva'),
        content: Text(
            'Deseja cancelar a reserva de ${a.quadraNome} em ${dataFmt.format(a.inicio)} às ${horaFmt.format(a.inicio)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Brand.danger),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final api = context.read<ApiClient>();
      await api.cancelarReserva(a.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reserva cancelada com sucesso.'),
              backgroundColor: Brand.green),
        );
        _carregar();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(mensagemErro(e, 'Erro ao cancelar.')),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0: return Colors.orange; // Pendente
      case 1: return Brand.green;   // Confirmado
      case 2: return Colors.blue;   // Concluído
      case 3: return Colors.grey;   // Cancelado
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(int status) {
    switch (status) {
      case 0: return Icons.schedule;
      case 1: return Icons.check_circle;
      case 2: return Icons.flag;
      case 3: return Icons.cancel;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.logado) {
      // Redireciona para a página inicial se perder a sessão
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.event_note),
          SizedBox(width: 8),
          Text('Minhas Reservas'),
        ]),
        actions: [
          if (!isCompact(context)) ...[
            Center(child: Text(auth.usuario!.nomeCompleto)),
            const SizedBox(width: 8),
          ],
          IconButton(
            tooltip: 'Nova reserva',
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erro!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _carregar,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _reservas.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('Nenhuma reserva encontrada.',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(
                              'Faça uma reserva para acompanhá-la aqui.',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () =>
                                  Navigator.pushReplacementNamed(context, '/'),
                              icon: const Icon(Icons.add),
                              label: const Text('Nova reserva'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final a in _reservas)
                            Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(_statusIcon(a.status),
                                            color: _statusColor(a.status),
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          a.statusLabel,
                                          style: TextStyle(
                                            color: _statusColor(a.status),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'R\$ ${a.valorTotal.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.sports_tennis,
                                            size: 18, color: Brand.green),
                                        const SizedBox(width: 6),
                                        Text(a.quadraNome,
                                            style:
                                                const TextStyle(fontSize: 15)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(dataFmt.format(a.inicio)),
                                        const SizedBox(width: 16),
                                        const Icon(Icons.access_time,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 6),
                                        Text(
                                            '${horaFmt.format(a.inicio)} — ${horaFmt.format(a.fim)}'),
                                      ],
                                    ),
                                    if (a.observacoes != null &&
                                        a.observacoes!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(a.observacoes!,
                                          style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 13)),
                                    ],
                                    if (a.cupomCodigo != null) ...[
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.discount,
                                              size: 16, color: Brand.amber),
                                          const SizedBox(width: 6),
                                          Text('Cupom: ${a.cupomCodigo}',
                                              style: TextStyle(
                                                  color: Brand.amber,
                                                  fontSize: 13)),
                                          if (a.valorDesconto > 0)
                                            Text(
                                                ' (-R\$ ${a.valorDesconto.toStringAsFixed(2)})',
                                                style: TextStyle(
                                                    color: Brand.green,
                                                    fontSize: 13)),
                                        ],
                                      ),
                                    ],
                                    if (a.status != 3 && a.status != 2) ...[
                                      // Não exibe botão de cancelar se já cancelado (3) ou concluído (2)
                                      const SizedBox(height: 12),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () => _cancelar(a),
                                          icon: const Icon(Icons.cancel_outlined,
                                              size: 18),
                                          label: const Text('Cancelar reserva'),
                                          style: TextButton.styleFrom(
                                              foregroundColor: Brand.danger),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}