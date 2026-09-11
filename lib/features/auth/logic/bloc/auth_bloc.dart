import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../../../core/session/session_manager.dart';
import 'auth_event.dart';
import 'auth_state.dart';

export 'auth_event.dart';
export 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final SessionManager _sessionManager;

  AuthBloc(
    this._authRepository,
    this._sessionManager,
  ) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<CadastroRequested>(_onCadastroRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      debugPrint('AUTH BLOC: Iniciando login');

      final user = await _authRepository.login(
        event.email,
        event.password,
      );

      await _sessionManager.startSession();

      debugPrint('AUTH BLOC: Login realizado com sucesso');

      emit(AuthSuccess(user));
    } catch (e) {
      debugPrint('AUTH BLOC: ERRO NO LOGIN: $e');

      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onCadastroRequested(
    CadastroRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      debugPrint('AUTH BLOC: Iniciando cadastro');

      final user = await _authRepository.cadastro(
        event.email,
        event.password,
        event.nome,
      );

      await _sessionManager.startSession();

      debugPrint('AUTH BLOC: Cadastro realizado com sucesso');

      emit(AuthSuccess(user));
    } catch (e) {
      debugPrint('AUTH BLOC: ERRO NO CADASTRO: $e');

      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await _authRepository.logout();

      await _sessionManager.clearSession();

      emit(AuthInitial());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}