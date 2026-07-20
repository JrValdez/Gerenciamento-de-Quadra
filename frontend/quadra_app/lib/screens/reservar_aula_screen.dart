import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

/// Tela do professor: reservar quadra para dar aula.
/// O valor usa o preço de aula do professor e a reserva já entra confirmada.
class ReservarAulaScreen extends StatefulWidget {
  const ReservarAulaScreen({super.key});
  @override
  State<ReservarAulaScreen> createState() => _ReservarAulaScreenState();
}

class _ReservarAulaScreenState extends State<ReservarAulaScreen> {
  late final ApiClient api = context.read<ApiClient>();

  List<Quadra> _quadras = [];
  Quadra? _quadra;
  Professor? _prof;
  DateTime _dia = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Slot> _slots = [];
  bool _carregando = true;
  bool _carregandoSlots = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final results = await Future.wait([api.quadras(), api.meuPrecoAula()]);
      final quadras = results[0] as List<Quadra>;
      setState(() {
        _quadras = quadras;
        _quadra = quadras.isNotEmpty ? quadras.first : null;
        _prof = results[1] as Professor;
        _carregando = false;
      });
      if (_quadra != null) _carregarSlots();
    } catch (e) {
      setState(() {
        _erro = 'Não foi possível carregar os dados. A API está no ar?';
        _carregando = false;
      });
    }
  }

  Future<void> _carregarSlots() async {
    if (_quadra == null) return;
    setState(() => _carregandoSlots = true);
    try {
      final s = await api.disponibilidade(_quadra!.id, DateTime(_dia.year, _dia.month, _dia.day));
      setState(() {
        _slots = s;
        _carregandoSlots = false;
      });
    } catch (e) {
      setState(() {
        _slots = [];
        _carregandoSlots = false;
      });
    }
  }

  Future<void> _reservar(Slot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReservaAulaDialog(quadra: _quadra!, slot: slot, prof: _prof!, api: api),
    );
    if (ok == true) {
      _carregarSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aula reservada e confirmada!'),
              backgroundColor: Brand.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_erro != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erro!)));
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _cabecalhoPreco(),
            const SizedBox(height: 16),
            DropdownButtonFormField<Quadra>(
              initialValue: _quadra,
              decoration: const InputDecoration(labelText: 'Quadra'),
              items: _quadras
                  .map((q) => DropdownMenuItem(
                      value: q,
                      child: Text('${q.nome}  •  '
                          '${q.horaAbertura.toString().padLeft(2, '0')}h-${q.horaFechamento.toString().padLeft(2, '0')}h')))
                  .toList(),
              onChanged: (q) {
                setState(() => _quadra = q);
                _carregarSlots();
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TableCalendar(
                  locale: 'pt_BR',
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 31)),
                  focusedDay: _focusedDay,
                  currentDay: DateTime.now(),
                  availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
                  selectedDayPredicate: (d) => isSameDay(d, _dia),
                  onDaySelected: (selected, focused) {
                    setState(() {
                      _dia = selected;
                      _focusedDay = focused;
                    });
                    _carregarSlots();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Brand.green.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Brand.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Horários de ${dataFmt.format(_dia)}',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_carregandoSlots)
              const Padding(
                  padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_slots.isEmpty)
              const Text('Nenhum horário para este dia.')
            else
              Wrap(spacing: 10, runSpacing: 10, children: _slots.map(_slotChip).toList()),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _cabecalhoPreco() {
    final preco = _prof?.precoAula ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.greenTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.green),
      ),
      child: Row(
        children: [
          const Icon(Icons.school, color: Brand.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reserve uma quadra para dar aula',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(preco > 0
                    ? 'Seu preço de aula: ${moeda.format(preco)}/hora'
                    : 'Seu preço de aula ainda não foi definido (R\$ 0). Fale com o atendente.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotChip(Slot s) {
    final label = '${horaFmt.format(s.inicio)} - ${horaFmt.format(s.fim)}';
    if (!s.disponivel) {
      return Chip(
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
      );
    }
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.check_circle, color: Brand.green, size: 18),
      backgroundColor: Brand.greenTint,
      side: const BorderSide(color: Brand.green),
      onPressed: () => _reservar(s),
    );
  }
}

class _ReservaAulaDialog extends StatefulWidget {
  final Quadra quadra;
  final Slot slot;
  final Professor prof;
  final ApiClient api;
  const _ReservaAulaDialog(
      {required this.quadra, required this.slot, required this.prof, required this.api});

  @override
  State<_ReservaAulaDialog> createState() => _ReservaAulaDialogState();
}

class _ReservaAulaDialogState extends State<_ReservaAulaDialog> {
  final _obs = TextEditingController();
  bool _enviando = false;
  String? _erro;

  double get _total =>
      widget.prof.precoAula * widget.slot.fim.difference(widget.slot.inicio).inMinutes / 60;

  @override
  void dispose() {
    _obs.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.api.reservarAula({
        'quadraId': widget.quadra.id,
        'inicio': widget.slot.inicio.toUtc().toIso8601String(),
        'fim': widget.slot.fim.toUtc().toIso8601String(),
        if (_obs.text.trim().isNotEmpty) 'observacoes': _obs.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _enviando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao reservar. Tente novamente.';
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Confirmar aula'),
      content: SizedBox(
        width: dialogW(context, 468),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.greenTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: Brand.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${widget.quadra.nome}\n${dataFmt.format(widget.slot.inicio)}  '
                      '${horaFmt.format(widget.slot.inicio)}-${horaFmt.format(widget.slot.fim)}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _obs,
              decoration: const InputDecoration(
                labelText: 'Observação / turma (opcional)',
                hintText: 'Ex.: Turma iniciante',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Valor da aula', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(moeda.format(_total),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviando ? null : _confirmar,
          child: _enviando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirmar aula'),
        ),
      ],
    );
  }
}
