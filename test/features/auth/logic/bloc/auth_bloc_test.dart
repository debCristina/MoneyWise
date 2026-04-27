import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:money_wise/features/auth/data/repositories/auth_repository.dart';
import 'package:money_wise/features/auth/domain/models/user.dart';
import 'package:money_wise/features/auth/logic/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthBloc authBloc;
  late MockAuthRepository mockAuthRepository;

  const tUser = User(id: '123', nome: 'Teste Silva', email: 'teste@teste.com');
  const tEmail = 'teste@teste.com';
  const tPassword = 'password123';
  const tNome = 'Teste Silva';

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    authBloc = AuthBloc(mockAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  test('O estado inicial deve ser AuthInitial', () {
    expect(authBloc.state, equals(AuthInitial()));
  });

  group('LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthSuccess] quando o login for bem-sucedido',
      build: () {
        when(() => mockAuthRepository.login(tEmail, tPassword))
            .thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthSuccess(tUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.login(tEmail, tPassword)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthError] quando o login falhar',
      build: () {
        when(() => mockAuthRepository.login(tEmail, tPassword))
            .thenThrow(AuthException('E-mail ou senha incorretos.'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LoginRequested(email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthError('E-mail ou senha incorretos.'),
      ],
    );
  });

  group('CadastroRequested', () {
    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthSuccess] quando o cadastro for bem-sucedido',
      build: () {
        when(() => mockAuthRepository.cadastro(tEmail, tPassword, tNome))
            .thenAnswer((_) async => tUser);
        return authBloc;
      },
      act: (bloc) => bloc.add(const CadastroRequested(nome: tNome, email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthSuccess(tUser),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.cadastro(tEmail, tPassword, tNome)).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthError] quando o cadastro falhar',
      build: () {
        when(() => mockAuthRepository.cadastro(tEmail, tPassword, tNome))
            .thenThrow(AuthException('Esse e-mail já está em uso por outra conta.'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const CadastroRequested(nome: tNome, email: tEmail, password: tPassword)),
      expect: () => [
        AuthLoading(),
        const AuthError('Esse e-mail já está em uso por outra conta.'),
      ],
    );
  });

  group('LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthInitial] quando o logout for bem-sucedido',
      build: () {
        when(() => mockAuthRepository.logout()).thenAnswer((_) async {});
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        AuthLoading(),
        AuthInitial(),
      ],
      verify: (_) {
        verify(() => mockAuthRepository.logout()).called(1);
      },
    );

    blocTest<AuthBloc, AuthState>(
      'deve emitir [AuthLoading, AuthError] quando o logout falhar',
      build: () {
        when(() => mockAuthRepository.logout())
            .thenThrow(Exception('Erro inesperado ao deslogar'));
        return authBloc;
      },
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [
        AuthLoading(),
        const AuthError('Exception: Erro inesperado ao deslogar'),
      ],
    );
  });
}
