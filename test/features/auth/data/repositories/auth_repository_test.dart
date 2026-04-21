import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:money_wise/features/auth/data/repositories/auth_repository.dart';

// Mocks do Mocktail para evitar uso real de rede ou emulador
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}
class MockUserCredential extends Mock implements firebase_auth.UserCredential {}
class MockFirebaseUser extends Mock implements firebase_auth.User {}

void main() {
  late MockFirebaseAuth mockFirebaseAuth;
  late AuthRepository authRepository;

  setUp(() {
    mockFirebaseAuth = MockFirebaseAuth();
    authRepository = AuthRepository(firebaseAuth: mockFirebaseAuth);
  });

  group('AuthRepository | Login |', () {
    test('Deve retornar User mapeado quando as credenciais estiverem corretas', () async {
      // Arrange
      final mockCredential = MockUserCredential();
      final mockFirebaseUser = MockFirebaseUser();

      when(() => mockFirebaseUser.uid).thenReturn('fake_uid');
      when(() => mockFirebaseUser.email).thenReturn('teste@teste.com');
      when(() => mockFirebaseUser.displayName).thenReturn('Teste da Silva');

      when(() => mockCredential.user).thenReturn(mockFirebaseUser);

      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'teste@teste.com',
            password: 'senha_super_falsa',
          )).thenAnswer((_) async => mockCredential);

      // Act
      final result = await authRepository.login('teste@teste.com', 'senha_super_falsa');

      // Assert
      expect(result.id, 'fake_uid');
      expect(result.nome, 'Teste da Silva');
      expect(result.email, 'teste@teste.com');
      verify(() => mockFirebaseAuth.signInWithEmailAndPassword(
          email: 'teste@teste.com', password: 'senha_super_falsa')).called(1);
    });

    test('Deve lançar AuthException traduzida quando houver erro do tipo invalid-email', () async {
      // Arrange
      when(() => mockFirebaseAuth.signInWithEmailAndPassword(
            email: 'email_errado',
            password: '123',
          )).thenThrow(firebase_auth.FirebaseAuthException(code: 'invalid-email'));

      // Act & Assert
      expect(
        () async => await authRepository.login('email_errado', '123'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            'O formato do e-mail é inválido.', // Nossa tradução implementada
          ),
        ),
      );
    });
  });

  group('AuthRepository | Cadastro |', () {
    test('Deve atualizar e retornar User quando o cadastro for aprovado pelo servidor', () async {
      // Arrange
      final mockCredential = MockUserCredential();
      final mockFirebaseUser = MockFirebaseUser();

      when(() => mockFirebaseUser.uid).thenReturn('abc_uid');
      when(() => mockFirebaseUser.email).thenReturn('novo@novo.com');
      // Importante simular os updates profile
      when(() => mockFirebaseUser.updateDisplayName('Joao'))
          .thenAnswer((_) async => {});

      when(() => mockCredential.user).thenReturn(mockFirebaseUser);

      when(() => mockFirebaseAuth.createUserWithEmailAndPassword(
            email: 'novo@novo.com',
            password: 'senhaboaaqui',
          )).thenAnswer((_) async => mockCredential);

      // Act
      final result = await authRepository.cadastro('novo@novo.com', 'senhaboaaqui', 'Joao');

      // Assert
      expect(result.id, 'abc_uid');
      expect(result.nome, 'Joao');
      // Verifica se ele realmente ligou a tela do Firebase Auth pra setar o display name
      verify(() => mockFirebaseUser.updateDisplayName('Joao')).called(1);
    });
  });
}
