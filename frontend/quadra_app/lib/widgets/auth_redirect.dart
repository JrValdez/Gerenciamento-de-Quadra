import 'package:flutter/material.dart';

/// Redireciona uma única vez para [rota] (após o frame atual) e mostra um spinner
/// enquanto isso. Substitui o `Navigator.pushReplacementNamed` chamado direto dentro
/// do `build` das shells — que disparava a cada rebuild; aqui, por ser um State
/// próprio, o `initState` roda uma vez só por instância.
class AuthRedirect extends StatefulWidget {
  final String rota;
  const AuthRedirect({super.key, required this.rota});

  @override
  State<AuthRedirect> createState() => _AuthRedirectState();
}

class _AuthRedirectState extends State<AuthRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pushReplacementNamed(context, widget.rota);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
