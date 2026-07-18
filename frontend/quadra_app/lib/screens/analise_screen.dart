import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

/// Painel de análises financeiras do caixa (somente Admin).
class AnaliseScreen extends StatefulWidget {
  const AnaliseScreen({super.key});
  @override
  State<AnaliseScreen> createState() => _AnaliseScreenState();
}

class _AnaliseScreenState extends State<AnaliseScreen> {
  late final ApiClient api = context.read<ApiClient>();
  AnaliseCaixa? _dados;
  bool _carregando = true;
  String? _erro;

  static const _verde = Color(0xFF1B7A3D);
  static const _vermelho = Color(0xFFC62828);

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
      final d = await api.analiseCaixa();
      setState(() {
        _dados = d;
        _carregando = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar análises: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erro!)));
    }
    final d = _dados!;
    return RefreshIndicator(
      onRefresh: _carregar,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Text('Análises do caixa', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(onPressed: _carregar, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, c) {
              final w = c.maxWidth;
              // 1 coluna (bem estreito), 2 colunas (médio) ou cards de 240 (largo).
              final cardW = w < 300 ? w : (w < 660 ? (w - 16) / 2 : 240.0);
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _cardPeriodo('Hoje', d.dia, Icons.today, cardW),
                  _cardPeriodo('Esta semana', d.semana, Icons.calendar_view_week, cardW),
                  _cardPeriodo('Este mês', d.mes, Icons.calendar_month, cardW),
                  _cardSaldo(d, cardW),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          Text('Fluxo de caixa (últimos 14 dias)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          const _Legenda(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: _FluxoChart(dados: d.fluxoDiario, verde: _verde, vermelho: _vermelho),
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, c) {
              final cat = _blocoCategorias(d.porCategoria);
              final formas = _blocoFormas(d.porFormaPagamento);
              if (c.maxWidth < 640) {
                return Column(children: [cat, const SizedBox(height: 16), formas]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: cat),
                  const SizedBox(width: 16),
                  Expanded(child: formas),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _cardPeriodo(String titulo, PeriodoResumo r, IconData icone, double largura) {
    return Container(
      width: largura,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(titulo, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(moeda.format(r.saldo),
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: r.saldo >= 0 ? _verde : _vermelho)),
          const Text('saldo do período', style: TextStyle(fontSize: 11, color: Colors.grey)),
          const Divider(height: 20),
          _linhaValor('Entradas', r.entradas, _verde, Icons.arrow_downward),
          const SizedBox(height: 4),
          _linhaValor('Saídas', r.saidas, _vermelho, Icons.arrow_upward),
          const SizedBox(height: 8),
          Text('${r.movimentacoes} movimentações',
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _cardSaldo(AnaliseCaixa d, double largura) {
    final aberto = d.caixaAberto;
    return Container(
      width: largura,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.point_of_sale, size: 18, color: Colors.white),
              SizedBox(width: 6),
              Text('Caixa atual',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(aberto ? moeda.format(d.saldoCaixaAtual ?? 0) : '—',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(aberto ? 'saldo esperado' : 'nenhum caixa aberto',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.85))),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(aberto ? 'ABERTO' : 'FECHADO',
                style: const TextStyle(
                    color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ],
      ),
    );
  }

  Widget _linhaValor(String label, double v, Color cor, IconData icone) {
    return Row(
      children: [
        Icon(icone, size: 14, color: cor),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Text(moeda.format(v), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
      ],
    );
  }

  Widget _blocoCategorias(List<CategoriaResumo> itens) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Por categoria (mês)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              const Text('Sem movimentações no mês.', style: TextStyle(color: Colors.grey))
            else
              ...itens.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(c.categoria)),
                        if (c.entradas > 0)
                          Text('+${moeda.format(c.entradas)}',
                              style: const TextStyle(color: _verde, fontWeight: FontWeight.w600)),
                        if (c.entradas > 0 && c.saidas > 0) const SizedBox(width: 8),
                        if (c.saidas > 0)
                          Text('-${moeda.format(c.saidas)}',
                              style: const TextStyle(color: _vermelho, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _blocoFormas(List<FormaPagamentoResumo> itens) {
    final total = itens.fold<double>(0, (s, f) => s + f.total);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recebido por forma (mês)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (itens.isEmpty)
              const Text('Sem recebimentos no mês.', style: TextStyle(color: Colors.grey))
            else
              ...itens.map((f) {
                final pct = total > 0 ? f.total / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(f.forma)),
                          Text(moeda.format(f.total),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          Text('${(pct * 100).round()}%',
                              style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 6,
                          backgroundColor: const Color(0xFFEEEEEE),
                          valueColor: const AlwaysStoppedAnimation(_verde),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _Legenda extends StatelessWidget {
  const _Legenda();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        _Ponto(cor: Color(0xFF1B7A3D)),
        SizedBox(width: 4),
        Text('Entradas', style: TextStyle(fontSize: 12, color: Colors.grey)),
        SizedBox(width: 16),
        _Ponto(cor: Color(0xFFC62828)),
        SizedBox(width: 4),
        Text('Saídas', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _Ponto extends StatelessWidget {
  final Color cor;
  const _Ponto({required this.cor});
  @override
  Widget build(BuildContext context) =>
      Container(width: 10, height: 10, decoration: BoxDecoration(color: cor, shape: BoxShape.circle));
}

/// Gráfico de barras (entradas x saídas por dia), sem dependências externas.
class _FluxoChart extends StatelessWidget {
  final List<FluxoDia> dados;
  final Color verde;
  final Color vermelho;
  const _FluxoChart({required this.dados, required this.verde, required this.vermelho});

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return const SizedBox(height: 120, child: Center(child: Text('Sem dados.')));
    }
    final fmtDia = DateFormat('dd/MM');
    final maxVal = dados
        .expand((d) => [d.entradas, d.saidas])
        .fold<double>(0, (m, v) => v > m ? v : m);
    final escala = maxVal <= 0 ? 1.0 : maxVal;
    const alturaBarras = 160.0;

    return SizedBox(
      height: alturaBarras + 46,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: dados.map((d) {
            final hE = (d.entradas / escala) * alturaBarras;
            final hS = (d.saidas / escala) * alturaBarras;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: alturaBarras,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _barra(hE, verde, d.entradas),
                        const SizedBox(width: 3),
                        _barra(hS, vermelho, d.saidas),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(fmtDia.format(d.dia), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _barra(double altura, Color cor, double valor) {
    return Tooltip(
      message: moeda.format(valor),
      child: Container(
        width: 14,
        height: altura < 2 && valor == 0 ? 2 : altura,
        decoration: BoxDecoration(
          color: valor == 0 ? const Color(0xFFEEEEEE) : cor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
        ),
      ),
    );
  }
}
