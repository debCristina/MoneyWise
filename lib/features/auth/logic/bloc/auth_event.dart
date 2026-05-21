import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class CadastroRequested extends AuthEvent {
  final String nome;
  final String email;
  final String password;

  const CadastroRequested({
    required this.nome,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [nome, email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
