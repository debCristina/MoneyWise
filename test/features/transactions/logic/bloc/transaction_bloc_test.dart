import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:money_wise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:money_wise/features/transactions/domain/models/transaction.dart';
import 'package:money_wise/features/transactions/logic/bloc/transactions_bloc.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late TransactionBloc bloc;
  late MockTransactionRepository mockRepository;

  final tDespesa = Transaction(
    id: 'txn-001',
    userId: 'user-123',
    value: 150.0,
    data: DateTime(2024, 6, 15),
    category: 'alimentacao',
    type: TransactionType.despesa,
  );

  final tReceita = Transaction(
    id: 'txn-002',
    userId: 'user-123',
    value: 4000.0,
    data: DateTime(2024, 6, 1),
    category: 'salario',
    type: TransactionType.receita,
  );

  setUp(() {
    mockRepository = MockTransactionRepository();
    bloc = TransactionBloc(mockRepository);
  });

  tearDown(() => bloc.close());

  test('estado inicial deve ser TransactionInitial', () {
    expect(bloc.state, isA<TransactionInitial>());
  });

  // ── LoadTransactionsEvent ───────────────────────────────────────────────

  group('LoadTransactionsEvent |', () {
    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Success] com lista e saldo corretos',
      build: () {
        when(() => mockRepository.getAll('user-123'))
            .thenAnswer((_) => Stream.value([tDespesa, tReceita]));
        return bloc;
      },
      act: (b) => b.add(const LoadTransactionsEvent('user-123')),
      expect: () => [
        TransactionLoading(),
        TransactionSuccess(
          transactions: [tDespesa, tReceita],
          saldo: 3850.0, // 4000 receita - 150 despesa
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.getAll('user-123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'deve emitir saldo zero quando não há transações',
      build: () {
        when(() => mockRepository.getAll('user-vazio'))
            .thenAnswer((_) => Stream.value([]));
        return bloc;
      },
      act: (b) => b.add(const LoadTransactionsEvent('user-vazio')),
      expect: () => [
        TransactionLoading(),
        const TransactionSuccess(transactions: [], saldo: 0.0),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Error] quando repositório lança exceção',
      build: () {
        when(() => mockRepository.getAll('user-123'))
            .thenThrow(Exception('Firestore indisponível'));
        return bloc;
      },
      act: (b) => b.add(const LoadTransactionsEvent('user-123')),
      expect: () => [
        TransactionLoading(),
        const TransactionError('Erro ao carregar transações.'),
      ],
    );
  });

  // ── AddTransactionEvent ─────────────────────────────────────────────────

  group('AddTransactionEvent |', () {
    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Success] com saldo atualizado após salvar despesa',
      build: () {
        when(() => mockRepository.save(tDespesa))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAll('user-123'))
            .thenAnswer((_) => Stream.value([tDespesa]));
        return bloc;
      },
      act: (b) => b.add(AddTransactionEvent(tDespesa)),
      expect: () => [
        TransactionLoading(),
        TransactionSuccess(
          transactions: [tDespesa],
          saldo: -150.0,
        ),
      ],
      verify: (_) {
        verify(() => mockRepository.save(tDespesa)).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Success] com saldo atualizado após salvar receita',
      build: () {
        when(() => mockRepository.save(tReceita))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAll('user-123'))
            .thenAnswer((_) => Stream.value([tReceita]));
        return bloc;
      },
      act: (b) => b.add(AddTransactionEvent(tReceita)),
      expect: () => [
        TransactionLoading(),
        TransactionSuccess(
          transactions: [tReceita],
          saldo: 4000.0,
        ),
      ],
    );

    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Error] quando save falhar',
      build: () {
        when(() => mockRepository.save(tDespesa))
            .thenThrow(Exception('Erro de rede'));
        return bloc;
      },
      act: (b) => b.add(AddTransactionEvent(tDespesa)),
      expect: () => [
        TransactionLoading(),
        const TransactionError('Erro ao salvar transação.'),
      ],
    );
  });

  // ── DeleteTransactionEvent ──────────────────────────────────────────────

  group('DeleteTransactionEvent |', () {
    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Success] com lista vazia após deletar única transação',
      build: () {
        when(() => mockRepository.delete('txn-001', 'user-123'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAll('user-123'))
            .thenAnswer((_) => Stream.value([]));
        return bloc;
      },
      act: (b) => b.add(const DeleteTransactionEvent(
        transactionId: 'txn-001',
        userId: 'user-123',
      )),
      expect: () => [
        TransactionLoading(),
        const TransactionSuccess(transactions: [], saldo: 0.0),
      ],
      verify: (_) {
        verify(() => mockRepository.delete('txn-001', 'user-123')).called(1);
      },
    );

    blocTest<TransactionBloc, TransactionState>(
      'deve emitir [Loading, Error] quando delete falhar',
      build: () {
        when(() => mockRepository.delete('txn-001', 'user-123'))
            .thenThrow(Exception('Documento não encontrado'));
        return bloc;
      },
      act: (b) => b.add(const DeleteTransactionEvent(
        transactionId: 'txn-001',
        userId: 'user-123',
      )),
      expect: () => [
        TransactionLoading(),
        const TransactionError('Erro ao deletar transação.'),
      ],
    );
  });
}