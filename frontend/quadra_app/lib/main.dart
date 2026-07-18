import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'api_client.dart';
import 'auth_provider.dart';
import 'theme.dart';
import 'screens/public_booking_screen.dart';
import 'screens/public_ranking_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'screens/aluno_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  final api = ApiClient();
  final auth = AuthProvider(api);
  // Restaura sessão salva antes de decidir a tela inicial.
  final restaurado = await auth.tryRestore();
  var rota = '/';
  if (restaurado) {
    if (auth.usuario!.isPainel) {
      rota = '/painel';
    } else if (auth.usuario!.isAluno) {
      rota = '/aluno';
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: api),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Gerenciamento de Quadra',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        routes: {
          '/': (_) => const PublicBookingScreen(),
          '/ranking': (_) => const PublicRankingScreen(),
          '/login': (_) => const LoginScreen(),
          '/painel': (_) => const HomeShell(),
          '/aluno': (_) => const AlunoShell(),
        },
        initialRoute: rotaInicial,
      ),
    );
  }
}
