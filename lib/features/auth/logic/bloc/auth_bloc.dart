import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/auth_repository.dart'; // Ajuste conforme o caminho real

// --- Estados (Subtarefa: Reagir a AuthLoading e AuthError) ---
abstract class AuthState {}
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- Eventos (Subtarefa: Disparar LoginRequested) ---
abstract class AuthEvent {}
class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested({required this.email, required this.password});
}

class CadastroRequested extends AuthEvent {
  final String nome;
  final String email;
  final String password;
  CadastroRequested({required this.nome, required this.email, required this.password});
}

// --- O BLoC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading()); // Inicia o carregamento (ativa o spinner no front)
      try {
        await _authRepository.login(event.email, event.password);
        emit(AuthAuthenticated()); // Navega para o Dashboard
      } catch (e) {
        emit(AuthError(e.toString())); // Exibe mensagem de erro
      }
    });

    on<CadastroRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _authRepository.cadastro(event.email, event.password, event.nome);
        emit(AuthAuthenticated());
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}