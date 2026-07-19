import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api_client.dart';
import '../models.dart';
import '../theme.dart';

/// Gestão do preço de aula por professor (Admin/Atendente).
class ProfessoresScreen extends StatefulWidget {
  const ProfessoresScreen({super.key});
  @override
  State<ProfessoresScreen> createState() => _ProfessoresScreenState();
}

class _ProfessoresScreenState extends State<ProfessoresScreen> {
  late final ApiClient api = context.read<ApiClient>();
  List<Professor> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    try {
      _itens = await api.professores();
    } catch (e) {
      _msg('Erro ao carregar: $e');
    }
    if (mounted) setState(() => _carregando = false);
  }

  void _msg(String m) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Future<void> _editarPreco(Professor p) async {
    final novo = await showDialog<double>(
      context: context,
      builder: (_) => _PrecoDialog(professor: p),
    );
    if (novo == null) return;
    try {
      await api.definirPrecoProfessor(p.id, novo);
      _msg('Preço de aula atualizado.');
      _carregar();
    } catch (e) {
      _msg('Erro: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) return const Center(child: CircularProgressIndicator());
    if (_itens.isEmpty) {
      return const Center(
        child: Text('Nenhum professor cadastrado.\nCrie usuários com papel Professor.',
            textAlign: TextAlign.center),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _itens.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final p = _itens[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF1B7A3D),
              child: Text(
                p.nomeCompleto.isNotEmpty ? p.nomeCompleto[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(p.nomeCompleto, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(p.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${moeda.format(p.precoAula)}/h',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('preço da aula',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Editar preço da aula',
                  onPressed: () => _editarPreco(p),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrecoDialog extends StatefulWidget {
  final Professor professor;
  const _PrecoDialog({required this.professor});
  @override
  State<_PrecoDialog> createState() => _PrecoDialogState();
}

class _PrecoDialogState extends State<_PrecoDialog> {
  final _form = GlobalKey<FormState>();
  late final _preco = TextEditingController(
      text: widget.professor.precoAula.toStringAsFixed(2).replaceAll('.', ','));

  @override
  void dispose() {
    _preco.dispose();
    super.dispose();
  }

  void _salvar() {
    if (!_form.currentState!.validate()) return;
    final valor = double.parse(_preco.text.trim().replaceAll(',', '.'));
    Navigator.pop(context, valor);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text('Preço da aula • ${widget.professor.nomeCompleto}'),
      content: SizedBox(
        width: dialogW(context, 428),
        child: Form(
          key: _form,
          child: TextFormField(
            controller: _preco,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Preço por hora (R\$)',
              prefixText: 'R\$ ',
            ),
            validator: (v) {
              final t = (v ?? '').trim().replaceAll(',', '.');
              final d = double.tryParse(t);
              if (d == null) return 'Valor inválido';
              if (d < 0) return 'Não pode ser negativo';
              return null;
            },
            onFieldSubmitted: (_) => _salvar(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: _salvar, child: const Text('Salvar')),
      ],
    );
  }
}
