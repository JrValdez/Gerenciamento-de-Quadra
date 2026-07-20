import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'api_client.dart';
import 'models.dart';

/// Estado de autenticação global. Guarda usuário logado e token.
///
/// O token é persistido no **sessionStorage** do navegador (e não no localStorage):
/// ele sobrevive ao refresh da aba, mas é descartado quando a aba/janela é fechada,
/// reduzindo a janela de exposição de um token roubado. Mantemos o esquema Bearer/JWT
/// (o CORS e o modelo de auth não mudam); a superfície de XSS do Flutter Web já é baixa
/// (renderiza em canvas, sem injeção de HTML/DOM da aplicação).
class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  AuthProvider(this.api);

  static const _kToken = 'quadra_token';

  Usuario? _usuario;
  bool _carregando = false;

  Usuario? get usuario => _usuario;
  bool get logado => _usuario != null;
  bool get carregando => _carregando;

  /// Tenta restaurar a sessão a partir do token salvo. Retorna true se válido.
  Future<bool> tryRestore() async {
    final token = web.window.sessionStorage.getItem(_kToken);
    if (token == null) return false;
    api.setToken(token);
    try {
      _usuario = await api.me();
      notifyListeners();
      return true;
    } catch (_) {
      api.setToken(null);
      web.window.sessionStorage.removeItem(_kToken);
      return false;
    }
  }

  Future<void> login(String email, String senha) async {
    _carregando = true;
    notifyListeners();
    try {
      final data = await api.login(email, senha);
      final token = data['token'] as String;
      api.setToken(token);
      _usuario = Usuario.fromJson(data['usuario'] as Map<String, dynamic>);
      web.window.sessionStorage.setItem(_kToken, token);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    api.setToken(null);
    _usuario = null;
    web.window.sessionStorage.removeItem(_kToken);
    notifyListeners();
  }
}
