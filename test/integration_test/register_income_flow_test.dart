import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_wise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:money_wise/features/transactions/domain/models/transaction.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fakeFirestore;
  late TransactionRepository repository;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repository = TransactionRepository(firestore: fakeFirestore);
  });

  // HU02 — CA1: sistema permite registrar receita informando o valor
  testWidgets('HU02 | fluxo completo: salvar receita e aparecer no relatório', (tester) async {
    final receita = Transaction(
      id: 'txn-receita-001',
      userId: 'user-123',
      value: 4000.0,
      data: DateTime(2024, 6, 15),
      category: 'salario',
      type: TransactionType.receita,
    );

    await repository.save(receita);

    final transacoes = await repository.getAll('user-123').first;

    expect(transacoes.first.type, equals(TransactionType.receita));
    expect(transacoes.first.value, equals(4000.0));
    expect(transacoes.first.category, equals('salario'));
  });

  // RAP002 — valor negativo rejeitado também em receitas
  testWidgets('HU02 | RAP002: receita com valor negativo deve ser rejeitada', (tester) async {
    expect(
          () => Transaction(
        id: 'txn-invalida',
        userId: 'user-123',
        value: -1.0,
        data: DateTime(2024, 6, 15),
        category: 'salario',
        type: TransactionType.receita,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}