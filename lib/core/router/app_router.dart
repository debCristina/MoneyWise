import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:money_wise/features/Home/presentation/home_page.dart';
import 'package:money_wise/features/auth/presentation/pages/login_page.dart';
import 'package:money_wise/features/auth/presentation/pages/cadastro_page.dart';
import 'package:money_wise/features/auth/data/repositories/auth_repository.dart';
import 'package:money_wise/core/session/session_manager.dart';

/// Converte o Stream de autenticação em um Listenable para o GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }
  late final StreamSubscription<dynamic> _subscription;
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthRepository authRepository;
  final SessionManager sessionManager;

  AppRouter({required this.authRepository, required this.sessionManager}) {
    // Escuta quando a sessão expirar no lifecycle do app para forçar logout no backend
    sessionManager.onSessionExpired = () async {
      await authRepository.logout();
      await sessionManager.clearSession();
      // Ao dar logout, o authStateChanges vai emitir null, o router vai detectar e jogar pra /login
    };
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
    redirect: (context, state) async {
      final user = authRepository.getCurrentUser();
      
      final isGoingToLoginOrCadastro = 
          state.matchedLocation == '/login' || state.matchedLocation == '/cadastro';

      if (user != null) {
        // Checagem extra de segurança na navegação
        if (sessionManager.isSessionExpired()) {
          await authRepository.logout();
          await sessionManager.clearSession();
          return '/login';
        }
        
        // Se estiver logado e tentando ir pro login/cadastro, joga pra home
        if (isGoingToLoginOrCadastro) {
          return '/home';
        }
      } else {
        // Se não tiver logado e estiver indo pra página que precisa de login, manda pro login
        if (!isGoingToLoginOrCadastro) {
          return '/login';
        }
      }

      // Nenhuma mudança na rota (segue fluxo normal)
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/cadastro',
        builder: (context, state) => const CadastroPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
