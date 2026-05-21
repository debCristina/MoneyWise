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

  // relatório contém despesas organizadas por período
  testWidgets('HU03 | relatório exibe transações ordenadas por data decrescente', (tester) async {
    await repository.save(Transaction(
      id: 'txn-jan',
      userId: 'user-123',
      value: 50.0,
      data: DateTime(2024, 1, 10),
      category: 'alimentacao',
      type: TransactionType.despesa,
    ));
    await repository.save(Transaction(
      id: 'txn-dez',
      userId: 'user-123',
      value: 150.0,
      data: DateTime(2024, 12, 20),
      category: 'lazer',
      type: TransactionType.despesa,
    ));

    final transacoes = await repository.getAll('user-123').first;


    // mais recente primeiro
    expect(transacoes.first.id, equals('txn-dez'));
    expect(transacoes.last.id, equals('txn-jan'));
  });

  // saldo calculado corretamente (receitas - despesas)
  testWidgets('HU03 | saldo total é a diferença entre receitas e despesas', (tester) async {
    await repository.save(Transaction(
      id: 'r1',
      userId: 'user-123',
      value: 4000.0,
      data: DateTime(2024, 6, 1),
      category: 'salario',
      type: TransactionType.receita,
    ));
    await repository.save(Transaction(
      id: 'd1',
      userId: 'user-123',
      value: 1000.0,
      data: DateTime(2024, 6, 5),
      category: 'aluguel',
      type: TransactionType.despesa,
    ));

    final transacoes = await repository.getAll('user-123').first;

    final totalReceitas = transacoes
        .where((t) => t.type == TransactionType.receita)
        .fold(0.0, (soma, t) => soma + t.value);

    final totalDespesas = transacoes
        .where((t) => t.type == TransactionType.despesa)
        .fold(0.0, (soma, t) => soma + t.value);

    expect(totalReceitas - totalDespesas, equals(3000.0));
  });

  // Isolamento: usuário só vê suas próprias transações
  testWidgets('HU03 | relatório nunca mistura dados de usuários diferentes', (tester) async {
    await repository.save(Transaction(
      id: 'minha',
      userId: 'user-123',
      value: 100.0,
      data: DateTime(2024, 6, 1),
      category: 'alimentacao',
      type: TransactionType.despesa,
    ));
    await repository.save(Transaction(
      id: 'de-outro',
      userId: 'user-999',
      value: 999.0,
      data: DateTime(2024, 6, 1),
      category: 'lazer',
      type: TransactionType.despesa,
    ));

    final transacoes = await repository.getAll('user-123').first;

    expect(transacoes.length, equals(1));
    expect(transacoes.every((t) => t.userId == 'user-123'), isTrue);
  });
}