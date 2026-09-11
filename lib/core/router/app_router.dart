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
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
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

  AppRouter({
    required this.authRepository,
    required this.sessionManager,
  }) {
    // Quando a sessão expirar, faz logout.
    // O authStateChanges emitirá null e o router redirecionará para /login.
    sessionManager.onSessionExpired = () async {
      await authRepository.logout();
      await sessionManager.clearSession();
    };
  }

  late final GoRouter router = GoRouter(
    initialLocation: '/login',

    refreshListenable: GoRouterRefreshStream(
      authRepository.authStateChanges(),
    ),

    redirect: (context, state) {
      final user = authRepository.getCurrentUser();

      final isGoingToLoginOrCadastro =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/cadastro';

      // Usuário logado
      if (user != null) {
        // Não deixa voltar para login ou cadastro
        if (isGoingToLoginOrCadastro) {
          return '/home';
        }
      } else {
        // Usuário não está logado
        if (!isGoingToLoginOrCadastro) {
          return '/login';
        }
      }

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