import 'package:flutter_test/flutter_test.dart';
import 'package:money_wise/features/auth/domain/models/user.dart';

void main() {
  group('User Model Tests |', () {
    test('Deve instanciar corretamente pelos construtores nomeados', () {
      const user = User(
        id: '123',
        nome: 'João',
        email: 'joao@teste.com',
      );

      expect(user.id, '123');
      expect(user.nome, 'João');
      expect(user.email, 'joao@teste.com');
    });

    test('Deve validar o construtor fromJson corretamente', () {
      final json = {
        'id': 'abc',
        'nome': 'Maria',
        'email': 'maria@teste.com',
      };

      final user = User.fromJson(json);

      expect(user.id, 'abc');
      expect(user.nome, 'Maria');
      expect(user.email, 'maria@teste.com');
    });

    test('Deve suportar fromJson com campos ausentes ou nulos para evitar crash na tela', () {
      final json = <String, dynamic>{
        'id': null,
        // nome is completely missing
        'email': null,
      };

      final user = User.fromJson(json);

      // We expect empty strings according to our implementation rules (using `?? ''`)
      expect(user.id, '');
      expect(user.nome, '');
      expect(user.email, '');
    });

    test('Deve serializar corretamente para toJson() compatível com Firestore', () {
      const user = User(
        id: 'xyz',
        nome: 'Pedro',
        email: 'pedro@teste.com',
      );

      final map = user.toJson();

      expect(map['id'], 'xyz');
      expect(map['nome'], 'Pedro');
      expect(map['email'], 'pedro@teste.com');
    });
  });
}
