import 'package:flutter/material.dart';

/// Controla um [AsyncView] de fora — ex.: recarregar depois de criar/editar algo
/// num diálogo disparado por um FloatingActionButton, que fica fora do corpo.
class AsyncViewController {
  Future<void> Function()? _reload;

  /// Recarrega os dados do [AsyncView] associado (no-op se não houver).
  Future<void> reload() async => await _reload?.call();
}

/// Padrão único de "carregar e exibir": cuida de loading, erro (com botão
/// "Tentar de novo") e recarga, eliminando a repetição de `_carregando`/`_erro`/
/// `initState` espalhada pelas telas. Durante uma recarga, os dados anteriores
/// continuam visíveis (não pisca o spinner).
class AsyncView<T> extends StatefulWidget {
  /// Busca os dados. Chamado no primeiro build e em cada recarga.
  final Future<T> Function() carregar;

  /// Constrói a tela com os dados; recebe também um callback para recarregar.
  final Widget Function(
    BuildContext context,
    T dados,
    Future<void> Function() recarregar,
  )
  builder;

  /// Opcional: permite recarregar a partir de fora (FAB, ação no AppBar...).
  final AsyncViewController? controlador;

  /// Opcional: mensagem amigável a partir do erro (o padrão não expõe detalhes técnicos).
  final String Function(Object erro)? mensagemErro;

  const AsyncView({
    super.key,
    required this.carregar,
    required this.builder,
    this.controlador,
    this.mensagemErro,
  });

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  T? _dados;
  Object? _erro;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    widget.controlador?._reload = _carregar;
    _carregar();
  }

  @override
  void dispose() {
    if (identical(widget.controlador?._reload, _carregar)) {
      widget.controlador?._reload = null;
    }
    super.dispose();
  }

  Future<void> _carregar() async {
    if (mounted) {
      setState(() {
        _carregando = true;
        _erro = null;
      });
    }
    try {
      final d = await widget.carregar();
      if (mounted) {
        setState(() {
          _dados = d;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _erro = e;
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Primeira carga em andamento: spinner.
    if (_carregando && _dados == null) {
      return const Center(child: CircularProgressIndicator());
    }
    // Falhou e não há nada para mostrar: mensagem amigável + tentar de novo.
    if (_erro != null && _dados == null) {
      final msg =
          widget.mensagemErro?.call(_erro!) ??
          'Não foi possível carregar. Verifique a conexão e tente novamente.';
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(msg, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _carregar,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar de novo'),
              ),
            ],
          ),
        ),
      );
    }
    return widget.builder(context, _dados as T, _carregar);
  }
}
