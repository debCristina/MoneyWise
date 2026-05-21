import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_wise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:money_wise/features/transactions/domain/models/transaction.dart';

void main() {
  group('TransactionRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late TransactionRepository repository;

    // Transação base reutilizada nos testes
    final transacaoBase = Transaction(
      id: 'txn-001',
      userId: 'user-123',
      value: 150.0,
      data: DateTime(2024, 6, 15),
      category: 'alimentacao',
      type: TransactionType.despesa,
    );

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      repository = TransactionRepository(firestore: fakeFirestore);
    });

    // ── SAVE ────────────────────────────────────────────────────────────────

    group('save()', () {
      test('persiste a transação no caminho correto do Firestore', () async {
        await repository.save(transacaoBase);

        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .doc('txn-001')
            .get();

        expect(doc.exists, isTrue);
      });

      test('salva os campos corretamente', () async {
        await repository.save(transacaoBase);

        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .doc('txn-001')
            .get();

        final data = doc.data()!;
        expect(data['value'], equals(150.0));
        expect(data['category'], equals('alimentacao'));
        expect(data['type'], equals('despesa'));
        expect(data['userId'], equals('user-123'));
      });

      test('não inclui o id no documento salvo', () async {
        await repository.save(transacaoBase);

        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .doc('txn-001')
            .get();

        expect(doc.data()!.containsKey('id'), isFalse);
      });

      test('quando id está vazio, cria documento com id gerado', () async {
        final semId = Transaction(
          id: '',
          userId: 'user-123',
          value: 50.0,
          data: DateTime(2024, 6, 15),
          category: 'transporte',
          type: TransactionType.despesa,
        );

        await repository.save(semId);

        final snapshot = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .get();

        expect(snapshot.docs.length, equals(1));
        expect(snapshot.docs.first.id, isNotEmpty);
      });

      test('sobrescreve transação existente com mesmo id', () async {
        await repository.save(transacaoBase);

        final atualizada = Transaction(
          id: 'txn-001',
          userId: 'user-123',
          value: 999.0,
          data: DateTime(2024, 6, 15),
          category: 'lazer',
          type: TransactionType.despesa,
        );

        await repository.save(atualizada);

        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .doc('txn-001')
            .get();

        expect(doc.data()!['value'], equals(999.0));
        expect(doc.data()!['category'], equals('lazer'));
      });
    });

    // ── GET ALL ─────────────────────────────────────────────────────────────

    group('getAll()', () {
      test('retorna stream com transações do userId correto', () async {
        await repository.save(transacaoBase);

        final stream = repository.getAll('user-123');
        final lista = await stream.first;

        expect(lista.length, equals(1));
        expect(lista.first.id, equals('txn-001'));
        expect(lista.first.userId, equals('user-123'));
      });

      test('nunca retorna dados de outro usuário', () async {
        await repository.save(transacaoBase); // user-123

        final outroUsuario = Transaction(
          id: 'txn-outro',
          userId: 'user-456',
          value: 200.0,
          data: DateTime(2024, 6, 15),
          category: 'saude',
          type: TransactionType.despesa,
        );
        await repository.save(outroUsuario);

        final stream = repository.getAll('user-123');
        final lista = await stream.first;

        expect(lista.length, equals(1));
        expect(lista.every((t) => t.userId == 'user-123'), isTrue);
      });

      test('retorna lista vazia quando usuário não tem transações', () async {
        final stream = repository.getAll('user-sem-dados');
        final lista = await stream.first;

        expect(lista, isEmpty);
      });

      test('retorna transações ordenadas por data decrescente', () async {
        final antiga = Transaction(
          id: 'txn-antiga',
          userId: 'user-123',
          value: 10.0,
          data: DateTime(2024, 1, 1),
          category: 'alimentacao',
          type: TransactionType.despesa,
        );
        final recente = Transaction(
          id: 'txn-recente',
          userId: 'user-123',
          value: 20.0,
          data: DateTime(2024, 12, 31),
          category: 'alimentacao',
          type: TransactionType.receita,
        );

        await repository.save(antiga);
        await repository.save(recente);

        final stream = repository.getAll('user-123');
        final lista = await stream.first;

        expect(lista.first.id, equals('txn-recente'));
        expect(lista.last.id, equals('txn-antiga'));
      });

      test('reconstrói Transaction com todos os campos corretos', () async {
        await repository.save(transacaoBase);

        final stream = repository.getAll('user-123');
        final lista = await stream.first;
        final t = lista.first;

        expect(t.id, equals('txn-001'));
        expect(t.userId, equals('user-123'));
        expect(t.value, equals(150.0));
        expect(t.category, equals('alimentacao'));
        expect(t.type, equals(TransactionType.despesa));
      });
    });

    // ── DELETE ───────────────────────────────────────────────────────────────

    group('delete()', () {
      test('remove a transação do Firestore', () async {
        await repository.save(transacaoBase);

        await repository.delete('txn-001', 'user-123');

        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-123')
            .collection('transactions')
            .doc('txn-001')
            .get();

        expect(doc.exists, isFalse);
      });

      test('só remove transações do próprio usuário', () async {
        await repository.save(transacaoBase); // user-123

        final outroUsuario = Transaction(
          id: 'txn-outro',
          userId: 'user-456',
          value: 200.0,
          data: DateTime(2024, 6, 15),
          category: 'saude',
          type: TransactionType.despesa,
        );
        await repository.save(outroUsuario);

        // deleta só do user-123
        await repository.delete('txn-001', 'user-123');

        // transação do user-456 continua lá
        final doc = await fakeFirestore
            .collection('transactions')
            .doc('user-456')
            .collection('transactions')
            .doc('txn-outro')
            .get();

        expect(doc.exists, isTrue);
      });

      test('não lança erro ao deletar id inexistente', () async {
        expect(
              () => repository.delete('id-que-nao-existe', 'user-123'),
          returnsNormally,
        );
      });
    });
  });
}