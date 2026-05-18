import 'package:flutter_test/flutter_test.dart';

import 'package:money_wise/features/transactions/domain/models/transaction.dart';

void main() {
  group('Transaction model', () {

    final mapaValido = {
      'id': 'txn-001',
      'userId': 'user-uuid-123',
      'value': 250.75,
      'data': DateTime(2024, 6, 15),
      'category': 'alimentacao',
      'type': 'despesa',
    };

    test('fromJson lança ArgumentError quando type é inválido', () {
      final mapaInvalido = {...mapaValido, 'type': 'invalido'};

      expect(
            () => Transaction.fromJson(mapaInvalido),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson cria Transaction com todos os campos corretos', () {
      final transaction = Transaction.fromJson(mapaValido);

      expect(transaction.id, equals('txn-001'));
      expect(transaction.userId, equals('user-uuid-123'));
      expect(transaction.value, equals(250.75));
      expect(transaction.data, equals(DateTime(2024, 6, 15)));
      expect(transaction.category, equals('alimentacao'));
      expect(transaction.type, equals(TransactionType.despesa));
    });

    test('toJson serializa type como String', () {
      final transaction = Transaction.fromJson(mapaValido);
      final json = transaction.toJson();

      expect(json['type'], equals('despesa'));
    });

    test('fromJson seguido de toJson não perde dados', () {
      final original = Transaction.fromJson(mapaValido);
      final restaurado = Transaction.fromJson(original.toJson());

      expect(restaurado.id, equals(original.id));
      expect(restaurado.userId, equals(original.userId));
      expect(restaurado.value, equals(original.value));
      expect(restaurado.category, equals(original.category));
      expect(restaurado.type, equals(original.type));
    });

  });
}