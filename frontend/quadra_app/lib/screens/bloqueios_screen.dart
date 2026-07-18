import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

class BloqueiosScreen extends StatefulWidget {
  const BloqueiosScreen({super.key});
  @override
  State<BloqueiosScreen> createState() => _BloqueiosScreenState();
}

class _BloqueiosScreenState extends State<BloqueiosScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Quadra> _quadras = [];
  List<Bloqueio> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _quadras = await api.quadras(incluirInativas: true);
      _itens = await api.bloqueios();
    } catch (e) {
      _msg('Erro: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  Future<void> _recarregar() async {
    try {
      _itens = await api.bloqueios();
      if (mounted) setState(() {});
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _novo() async {
    if (_quadras.isEmpty) {
      _msg('Cadastre uma quadra primeiro.');
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _BloqueioDialog(api: api, quadras: _quadras),
    );
    if (ok == true) {
      _msg('Bloqueio criado!');
      _recarregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _novo,
        icon: const Icon(Icons.block),
        label: const Text('Bloquear horário'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 20, 24, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Marque quando uma quadra ficará indisponível (manutenção, evento, folga). '
                      'Esses horários somem da reserva pública.',
                    ),
                  ),
                ),
                Expanded(
                  child: _itens.isEmpty
                      ? const Center(child: Text('Nenhum bloqueio ativo.'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(24),
                          itemCount: _itens.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_itens[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _card(Bloqueio b) {
    // Dia inteiro se cobre da meia-noite à meia-noite (ou quase).
    final diaInteiro = b.inicio.hour == 0 &&
        (b.fim.difference(b.inicio).inHours >= 23);
    final quando = diaInteiro
        ? '${dataFmt.format(b.inicio)} • dia inteiro'
        : '${dataFmt.format(b.inicio)} • ${horaFmt.format(b.inicio)} às ${horaFmt.format(b.fim)}';
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFDE7E7),
          child: Icon(Icons.block, color: Colors.red),
        ),
        title: Text(b.quadraNome, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$quando${b.motivo != null && b.motivo!.isNotEmpty ? '\n${b.motivo}' : ''}'),
        isThreeLine: b.motivo != null && b.motivo!.isNotEmpty,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Remover bloqueio',
          onPressed: () async {
            try {
              await api.excluirBloqueio(b.id);
              _recarregar();
            } catch (e) {
              _msg('Erro: $e');
            }
          },
        ),
      ),
    );
  }
}

class _BloqueioDialog extends StatefulWidget {
  final ApiClient api;
  final List<Quadra> quadras;
  const _BloqueioDialog({required this.api, required this.quadras});
  @override
  State<_BloqueioDialog> createState() => _BloqueioDialogState();
}

class _BloqueioDialogState extends State<_BloqueioDialog> {
  late Quadra _quadra = widget.quadras.first;
  DateTime _dia = DateTime.now();
  bool _diaInteiro = false;
  int _horaInicio = 8;
  int _horaFim = 22;
  final _motivo = TextEditingController();
  bool _salvando = false;
  String? _erro;

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  Future<void> _escolherData() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dia,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _dia = d);
  }

  Future<void> _salvar() async {
    if (!_diaInteiro && _horaFim <= _horaInicio) {
      setState(() => _erro = 'Hora final deve ser maior que a inicial.');
      return;
    }
    final DateTime inicio;
    final DateTime fim;
    if (_diaInteiro) {
      inicio = DateTime(_dia.year, _dia.month, _dia.day);
      fim = inicio.add(const Duration(days: 1));
    } else {
      inicio = DateTime(_dia.year, _dia.month, _dia.day, _horaInicio);
      fim = DateTime(_dia.year, _dia.month, _dia.day, _horaFim);
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await widget.api.criarBloqueio({
        'quadraId': _quadra.id,
        'inicio': inicio.toUtc().toIso8601String(),
        'fim': fim.toUtc().toIso8601String(),
        'motivo': _motivo.text.trim().isEmpty ? null : _motivo.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() {
        _erro = e.message;
        _salvando = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Falha ao salvar.';
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bloquear horário'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Quadra>(
              initialValue: _quadra,
              decoration: const InputDecoration(labelText: 'Quadra'),
              items: widget.quadras
                  .map((q) => DropdownMenuItem(value: q, child: Text(q.nome)))
                  .toList(),
              onChanged: (q) => setState(() => _quadra = q!),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _escolherData,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Dia'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dataFmt.format(_dia)),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Dia inteiro'),
              value: _diaInteiro,
              onChanged: (v) => setState(() => _diaInteiro = v),
            ),
            if (!_diaInteiro)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _horaInicio,
                      decoration: const InputDecoration(labelText: 'Das'),
                      items: [
                        for (var h = 0; h <= 23; h++)
                          DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')),
                      ],
                      onChanged: (v) => setState(() => _horaInicio = v ?? 8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _horaFim,
                      decoration: const InputDecoration(labelText: 'Até'),
                      items: [
                        for (var h = 1; h <= 24; h++)
                          DropdownMenuItem(value: h, child: Text('${h.toString().padLeft(2, '0')}:00')),
                      ],
                      onChanged: (v) => setState(() => _horaFim = v ?? 22),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _motivo,
              decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)', hintText: 'Ex.: Manutenção'),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _salvando ? null : _salvar,
          child: _salvando
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Bloquear'),
        ),
      ],
    );
  }
}
