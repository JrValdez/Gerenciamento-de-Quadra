import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';
import 'models.dart';

/// Estado de autenticação global. Guarda usuário logado e token,
/// persistindo o token no navegador (shared_preferences).
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    if (token == null) return false;
    api.setToken(token);
    try {
      _usuario = await api.me();
      notifyListeners();
      return true;
    } catch (_) {
      api.setToken(null);
      await prefs.remove(_kToken);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kToken, token);
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    api.setToken(null);
    _usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    notifyListeners();
  }
}
