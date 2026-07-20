import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class PublicBookingScreen extends StatefulWidget {
  const PublicBookingScreen({super.key});
  @override
  State<PublicBookingScreen> createState() => _PublicBookingScreenState();
}

class _PublicBookingScreenState extends State<PublicBookingScreen> {
  late final ApiClient api = context.read<ApiClient>();

  List<Quadra> _quadras = [];
  Quadra? _quadra;
  DateTime _dia = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<Slot> _slots = [];
  bool _carregandoQuadras = true;
  bool _carregandoSlots = false;
  String? _erro;

  /// Quantos blocos de 30 min livres e consecutivos existem a partir de [start].
  int _blocosLivres(int start) {
    var n = 0;
    for (var k = start; k < _slots.length && _slots[k].disponivel; k++) {
      n++;
    }
    return n;
  }

  @override
  void initState() {
    super.initState();
    _carregarQuadras();
  }

  Future<void> _carregarQuadras() async {
    try {
      final q = await api.quadras();
      setState(() {
        _quadras = q;
        _quadra = q.isNotEmpty ? q.first : null;
        _carregandoQuadras = false;
      });
      if (_quadra != null) _carregarSlots();
    } catch (e) {
      setState(() {
        _erro = 'Não foi possível carregar as quadras. A API está no ar?';
        _carregandoQuadras = false;
      });
    }
  }

  Future<void> _carregarSlots() async {
    if (_quadra == null) return;
    setState(() => _carregandoSlots = true);
    try {
      // Slots de 30 min para permitir reservas de 1h, 1h30, 2h... (faixas consecutivas).
      final s = await api.disponibilidade(
          _quadra!.id, DateTime(_dia.year, _dia.month, _dia.day),
          slotMinutos: 30);
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

  /// Toque num horário de início: abre o modal de reserva já com as durações que
  /// cabem a partir dali (limitadas pelo próximo horário ocupado e pelo fechamento).
  Future<void> _onTapSlot(int i) async {
    if (!_slots[i].disponivel) return;
    final maxMin = _blocosLivres(i) * 30;
    final duracoes = [for (var d = 30; d <= maxMin; d += 30) d];
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ReservaDialog(
          quadra: _quadra!, inicio: _slots[i].inicio, duracoes: duracoes, api: api),
    );
    if (ok == true) {
      _carregarSlots();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reserva solicitada! Confirmaremos em breve.'),
              backgroundColor: Brand.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.sports_tennis),
          SizedBox(width: 8),
          Text('Reserva de Quadras'),
        ]),
        actions: [
          if (isCompact(context)) ...[
            IconButton(
              tooltip: 'Ranking',
              onPressed: () => Navigator.pushNamed(context, '/ranking'),
              icon: const Icon(Icons.emoji_events),
            ),
            IconButton(
              tooltip: 'Área do funcionário',
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.lock_outline),
            ),
          ] else ...[
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/ranking'),
              icon: const Icon(Icons.emoji_events),
              label: const Text('Ranking'),
            ),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Área do funcionário'),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _carregandoQuadras
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_erro!)))
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 12),
                        _Hero(),
                        const SizedBox(height: 24),
                        DropdownButtonFormField<Quadra>(
                          initialValue: _quadra,
                          decoration: const InputDecoration(labelText: 'Quadra'),
                          items: _quadras
                              .map((q) => DropdownMenuItem(
                                  value: q,
                                  child: Text('${q.nome}  •  ${moeda.format(q.precoHora)}/h  •  '
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
                        const SizedBox(height: 4),
                        Text(
                            'Toque no horário de início e escolha a duração (1h, 1h30, 2h...).',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(height: 12),
                        if (_carregandoSlots)
                          const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator()))
                        else if (_slots.isEmpty)
                          const Text('Nenhum horário para este dia.')
                        else
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (var i = 0; i < _slots.length; i++) _slotChip(i),
                            ],
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _slotChip(int i) {
    final s = _slots[i];
    final label = horaFmt.format(s.inicio);
    if (!s.disponivel) {
      return Chip(
        label: Text(label),
        backgroundColor: Colors.grey.shade200,
        labelStyle: TextStyle(color: Colors.grey.shade500, decoration: TextDecoration.lineThrough),
      );
    }
    return ActionChip(
      label: Text(label),
      backgroundColor: Brand.greenTint,
      side: const BorderSide(color: Brand.green),
      onPressed: () => _onTapSlot(i),
    );
  }
}

String _fmtDuracao(int min) {
  final h = min ~/ 60;
  final m = min % 60;
  if (h == 0) return '${m}min';
  if (m == 0) return '${h}h';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: Brand.heroGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Brand.green.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(Icons.sports_tennis,
                size: 120, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('SEM CADASTRO',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1)),
              ),
              const SizedBox(height: 14),
              Text('Reserve sua quadra\nem segundos',
                  style: GoogleFonts.barlowCondensed(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.05,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Escolha a quadra, o dia no calendário e o horário. Depois é só informar nome, telefone e e-mail.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15, height: 1.4)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReservaDialog extends StatefulWidget {
  final Quadra quadra;
  final DateTime inicio;
  final List<int> duracoes; // durações possíveis (min), em passos de 30
  final ApiClient api;
  const _ReservaDialog(
      {required this.quadra, required this.inicio, required this.duracoes, required this.api});

  @override
  State<_ReservaDialog> createState() => _ReservaDialogState();
}

class _ReservaDialogState extends State<_ReservaDialog> {
  final _form = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _cupom = TextEditingController();
  late int _duracaoMin;
  bool _enviando = false;
  bool _validandoCupom = false;
  Cupom? _cupomAplicado;
  String? _cupomErro;
  String? _erro;

  @override
  void initState() {
    super.initState();
    // Pré-seleciona 1h se couber; senão, a maior duração disponível.
    _duracaoMin = widget.duracoes.contains(60) ? 60 : widget.duracoes.last;
  }

  DateTime get _fim => widget.inicio.add(Duration(minutes: _duracaoMin));

  /// Preço da reserva, proporcional à duração escolhida.
  double get _bruto => widget.quadra.precoHora * _duracaoMin / 60;

  double get _desconto {
    final c = _cupomAplicado;
    if (c == null) return 0;
    final d = c.tipo == 0 ? _bruto * c.valor / 100 : c.valor;
    return d > _bruto ? _bruto : d;
  }

  double get _total => _bruto - _desconto;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _email.dispose();
    _cupom.dispose();
    super.dispose();
  }

  Future<void> _aplicarCupom() async {
    final codigo = _cupom.text.trim();
    if (codigo.isEmpty) {
      setState(() {
        _cupomAplicado = null;
        _cupomErro = null;
      });
      return;
    }
    setState(() {
      _validandoCupom = true;
      _cupomErro = null;
    });
    try {
      final c = await widget.api.validarCupom(codigo);
      setState(() {
        _cupomAplicado = c;
        _validandoCupom = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _cupomAplicado = null;
        _cupomErro = e.message;
        _validandoCupom = false;
      });
    } catch (_) {
      setState(() {
        _cupomAplicado = null;
        _cupomErro = 'Não foi possível validar o cupom.';
        _validandoCupom = false;
      });
    }
  }

  Future<void> _confirmar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await widget.api.agendarPublico({
        'quadraId': widget.quadra.id,
        'inicio': widget.inicio.toUtc().toIso8601String(),
        'fim': _fim.toUtc().toIso8601String(),
        'nomeCliente': _nome.text.trim(),
        'telefoneCliente': _telefone.text.trim(),
        'emailCliente': _email.text.trim(),
        if (_cupomAplicado != null) 'cupomCodigo': _cupomAplicado!.codigo,
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _enviando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao enviar. Tente novamente.';
        _enviando = false;
      });
    }
  }

  Widget _resumoValores() {
    final temDesconto = _desconto > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6F4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _linhaValor('Subtotal', moeda.format(_bruto)),
          if (temDesconto) ...[
            const SizedBox(height: 4),
            _linhaValor(
              'Desconto${_cupomAplicado != null ? ' (${_cupomAplicado!.codigo})' : ''}',
              '- ${moeda.format(_desconto)}',
              cor: Brand.green,
            ),
          ],
          const Divider(height: 16),
          _linhaValor('Total', moeda.format(_total), negrito: true),
        ],
      ),
    );
  }

  Widget _linhaValor(String label, String valor, {bool negrito = false, Color? cor}) {
    final estilo = TextStyle(
      fontWeight: negrito ? FontWeight.bold : FontWeight.normal,
      fontSize: negrito ? 16 : 14,
      color: cor,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: estilo), Text(valor, style: estilo)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Confirmar reserva'),
      content: SizedBox(
        width: dialogW(context, 468),
        child: Form(
          key: _form,
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
                        '${widget.quadra.nome}\n${dataFmt.format(widget.inicio)}  '
                        '${horaFmt.format(widget.inicio)}-${horaFmt.format(_fim)}  •  ${_fmtDuracao(_duracaoMin)}\n'
                        '${moeda.format(widget.quadra.precoHora)}/h',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Quanto tempo?',
                    style: Theme.of(context).textTheme.labelLarge),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.duracoes.map((d) {
                  final sel = d == _duracaoMin;
                  return ChoiceChip(
                    label: Text(_fmtDuracao(d)),
                    selected: sel,
                    onSelected: (_) => setState(() => _duracaoMin = d),
                    selectedColor: Brand.green,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : null,
                        fontWeight: sel ? FontWeight.w600 : null),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome completo'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Telefone / WhatsApp'),
                validator: (v) => (v == null || v.trim().length < 8) ? 'Telefone inválido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'E-mail inválido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cupom,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Cupom de desconto (opcional)',
                        errorText: _cupomErro,
                        suffixIcon: _cupomAplicado != null
                            ? const Icon(Icons.check_circle, color: Brand.green)
                            : null,
                      ),
                      onChanged: (_) {
                        if (_cupomAplicado != null || _cupomErro != null) {
                          setState(() {
                            _cupomAplicado = null;
                            _cupomErro = null;
                          });
                        }
                      },
                      onFieldSubmitted: (_) => _aplicarCupom(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _validandoCupom ? null : _aplicarCupom,
                      child: _validandoCupom
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _resumoValores(),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
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
              : const Text('Confirmar reserva'),
        ),
      ],
    );
  }
}
