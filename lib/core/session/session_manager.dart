import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager with WidgetsBindingObserver {
  static const String _lastActiveKey = 'last_active_time';
  static const int _sessionTimeoutMinutes = 10;
  
  late final SharedPreferences _prefs;

  // Função callback opcional para ser notificado quando a sessão expirar (ex: para forçar router a rodar)
  VoidCallback? onSessionExpired;

  // Inicializa o shared preferences e se registra como observer
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    WidgetsBinding.instance.addObserver(this);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App foi pro background ou foi fechado, salva o tempo
      updateLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      // App voltou, checamos se expirou
      if (isSessionExpired()) {
        onSessionExpired?.call();
      } else {
        // Se não expirou, renovamos o tempo atual
        updateLastActiveTime();
      }
    }
  }

  /// Salva a hora atual como o momento da última atividade
  Future<void> updateLastActiveTime() async {
    await _prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Limpa a chave de sessão (útil no logout manual)
  Future<void> clearSession() async {
    await _prefs.remove(_lastActiveKey);
  }

  /// Verifica se a sessão expirou
  bool isSessionExpired() {
    final lastActiveEpoch = _prefs.getInt(_lastActiveKey);
    // Se não tem dado, acabou de instalar ou limpou cache, consideramos que tem que logar de novo
    if (lastActiveEpoch == null) return true;

    final lastActiveTime = DateTime.fromMillisecondsSinceEpoch(lastActiveEpoch);
    final difference = DateTime.now().difference(lastActiveTime);

    return difference.inMinutes >= _sessionTimeoutMinutes;
  }
}

