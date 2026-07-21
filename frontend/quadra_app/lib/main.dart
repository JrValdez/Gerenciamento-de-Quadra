import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'auth_provider.dart';
import 'theme.dart';
import 'screens/public_booking_screen.dart';
import 'screens/public_ranking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/esqueci_senha_screen.dart';
import 'screens/redefinir_senha_screen.dart';
import 'screens/home_shell.dart';
import 'screens/aluno_shell.dart';
import 'screens/minhas_reservas_screen.dart';

// Parâmetros do link de redefinição, lidos da URL em main() e usados pela rota.
String _resetEmail = '';
String _resetToken = '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final api = ApiClient();
  final auth = AuthProvider(api);

  // Rota inicial vinda da URL. No hash routing, a rota que a engine capturou no
  // carregamento (defaultRouteName) já traz a query — é onde chega o link de
  // redefinição de senha aberto do e-mail (com email e token).
  var rotaStr = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  if (!rotaStr.contains('token=') && Uri.base.fragment.contains('token=')) {
    rotaStr = Uri.base.fragment;
  }
  final uri = Uri.tryParse(rotaStr.isNotEmpty ? rotaStr : '/');

  var rota = '/';
  if (uri != null && uri.path == '/redefinir-senha') {
    _resetEmail = uri.queryParameters['email'] ?? '';
    _resetToken = uri.queryParameters['token'] ?? '';
    rota = '/redefinir-senha';
  } else {
    // Restaura sessão salva antes de decidir a tela inicial.
    final restaurado = await auth.tryRestore();
        if (restaurado) {
          if (auth.usuario!.isPainel) {
            rota = '/painel';
          } else if (auth.usuario!.isAluno) {
            rota = '/aluno';
          } else if (auth.usuario!.isCliente) {
            rota = '/minhas-reservas';
          }
        }
  }
  runApp(QuadraApp(api: api, auth: auth, rotaInicial: rota));
}

class QuadraApp extends StatelessWidget {
  final ApiClient api;
  final AuthProvider auth;
  final String rotaInicial;
  const QuadraApp({
    super.key,
    required this.api,
    required this.auth,
    required this.rotaInicial,
  });

  static final Map<String, WidgetBuilder> _rotas = {
    '/': (_) => const PublicBookingScreen(),
    '/ranking': (_) => const PublicRankingScreen(),
    '/login': (_) => const LoginScreen(),
    '/esqueci-senha': (_) => const EsqueciSenhaScreen(),
    '/redefinir-senha': (_) =>
        RedefinirSenhaScreen(email: _resetEmail, token: _resetToken),
    '/painel': (_) => const HomeShell(),
    '/aluno': (_) => const AlunoShell(),
    '/minhas-reservas': (_) => const MinhasReservasScreen(),
  };

  @override
  Widget build(BuildContext context) {
    final inicial = _rotas[rotaInicial] ?? _rotas['/']!;
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Gerenciamento de Quadra',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        // A tela inicial é montada direto (não depende da geração de pilha do
        // initialRoute). onGenerateRoute cobre a navegação nomeada (pushNamed).
        home: inicial(context),
        onGenerateRoute: (settings) {
          final b = _rotas[settings.name];
          return b == null ? null : MaterialPageRoute(settings: settings, builder: b);
        },
      ),
    );
  }
}
