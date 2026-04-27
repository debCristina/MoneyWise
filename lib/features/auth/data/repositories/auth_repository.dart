import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/models/user.dart';

/// Exceção personalizada legível pela camada de BLoC/UI
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

class AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  /// Permite injeção de dependência para testes, mas usa a instância padrão se null
  AuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  /// Converte o usuário do Firebase para o modelo puro do domínio
  User _mapFirebaseUser(firebase_auth.User? firebaseUser, {String? defaultNome}) {
    if (firebaseUser == null) {
      throw AuthException('Usuário não retornado pelo servidor.');
    }
    return User(
      id: firebaseUser.uid,
      nome: firebaseUser.displayName ?? defaultNome ?? 'Usuário',
      email: firebaseUser.email ?? '',
    );
  }

  /// Traduz os códigos de erro do Firebase para mensagens amigáveis em português
  String _handleFirebaseError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'user-not-found':
        return 'Nenhum usuário encontrado para este e-mail.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-mail ou senha incorretos.';
      case 'email-already-in-use':
        return 'Esse e-mail já está em uso por outra conta.';
      case 'weak-password':
        return 'A senha digitada é muito fraca. Tente uma mais forte.';
      case 'user-disabled':
        return 'Esta conta de usuário foi bloqueada ou desativada.';
      case 'too-many-requests':
        return 'Muitas tentativas falhas. Tente novamente mais tarde.';
      default:
        return 'Ocorreu um erro na autenticação. Tente novamente.';
    }
  }

  /// Método de login
  Future<User> login(String email, String senha) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: senha,
      );
      return _mapFirebaseUser(userCredential.user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException('Erro inesperado: $e');
    }
  }

  /// Método de cadastro
  Future<User> cadastro(String email, String senha, String nome) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      // Atualiza o perfil do usuário dentro do Firebase com o nome desejado
      await userCredential.user?.updateDisplayName(nome);

      // Retorna nosso usuário mapeado aproveitando o nome inserido
      return _mapFirebaseUser(userCredential.user, defaultNome: nome);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_handleFirebaseError(e));
    } catch (e) {
      throw AuthException('Erro inesperado: $e');
    }
  }

  /// Método de logout
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  /// Retorna o usuário logado atual, se houver
  User? getCurrentUser() {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  /// Retorna um Stream reagindo em tempo real a mudanças de autenticação
  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      // Trata exceção dentro do map se _mapFirebaseUser falhar por algum motivo imprevisto
      try {
        return _mapFirebaseUser(firebaseUser);
      } catch (e) {
        return null;
      }
    });
  }
}
