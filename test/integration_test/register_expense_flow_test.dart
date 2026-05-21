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

  // sistema permite registrar despesa informando o valor
  testWidgets('HU01 | fluxo completo: salvar despesa e recuperar no relatório', (tester) async {
    // 1. Usuário preenche os campos e salva a despesa (RAP001 — campos obrigatórios)
    final despesa = Transaction(
      id: 'txn-despesa-001',
      userId: 'user-123',
      value: 100.0,
      data: DateTime(2024, 6, 15),
      category: 'alimentacao',
      type: TransactionType.despesa,
    );

    await repository.save(despesa);

    // 2. A despesa aparece no relatório do usuário
    final stream = repository.getAll('user-123');
    final transacoes = await stream.first;

    expect(transacoes, isNotEmpty);
    expect(transacoes.first.type, equals(TransactionType.despesa));
    expect(transacoes.first.value, equals(100.0));
  });

  //campo valor só aceita positivos
  testWidgets('HU01 | RAP002: valor negativo deve ser rejeitado', (tester) async {
    expect(
          () => Transaction(
        id: 'txn-invalida',
        userId: 'user-123',
        value: -50.0,
        data: DateTime(2024, 6, 15),
        category: 'alimentacao',
        type: TransactionType.despesa,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  // Fluxo de deleção (CRUD completo)
  testWidgets('HU01 | deletar despesa remove do relatório', (tester) async {
    final despesa = Transaction(
      id: 'txn-delete',
      userId: 'user-123',
      value: 200.0,
      data: DateTime(2024, 6, 15),
      category: 'transporte',
      type: TransactionType.despesa,
    );

    await repository.save(despesa);
    await repository.delete('txn-delete', 'user-123');

    final transacoes = await repository.getAll('user-123').first;
    expect(transacoes.where((t) => t.id == 'txn-delete'), isEmpty);
  });
}