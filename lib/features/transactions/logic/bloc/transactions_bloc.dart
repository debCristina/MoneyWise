import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:money_wise/features/transactions/data/repositories/transaction_repository.dart';
import 'package:money_wise/features/transactions/domain/models/transaction.dart';


abstract class TransactionEvent extends Equatable {
  const TransactionEvent();

  @override
  List<Object?> get props => [];
}

class LoadTransactionsEvent extends TransactionEvent {
  final String userId;

  const LoadTransactionsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddTransactionEvent extends TransactionEvent {
  final Transaction transaction;

  const AddTransactionEvent(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransactionEvent extends TransactionEvent {
  final String transactionId;
  final String userId;

  const DeleteTransactionEvent({
    required this.transactionId,
    required this.userId,
  });

  @override
  List<Object?> get props => [transactionId, userId];
}

// ── States ───────────────────────────────────────────────────────────────────

abstract class TransactionState extends Equatable {
  const TransactionState();

  @override
  List<Object?> get props => [];
}

class TransactionInitial extends TransactionState {}

class TransactionLoading extends TransactionState {}

class TransactionSuccess extends TransactionState {
  final List<Transaction> transactions;
  final double saldo;

  const TransactionSuccess({
    required this.transactions,
    required this.saldo,
  });

  @override
  List<Object?> get props => [transactions, saldo];
}

class TransactionError extends TransactionState {
  final String message;

  const TransactionError(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Bloc ─────────────────────────────────────────────────────────────────────

class TransactionBloc extends Bloc<TransactionEvent, TransactionState> {
  final TransactionRepository repository;

  TransactionBloc(this.repository) : super(TransactionInitial()) {
    on<LoadTransactionsEvent>(_onLoad);
    on<AddTransactionEvent>(_onAdd);
    on<DeleteTransactionEvent>(_onDelete);
  }

  double _calcularSaldo(List<Transaction> transactions) {
    return transactions.fold(0.0, (saldo, t) {
      return t.type == TransactionType.receita
          ? saldo + t.value
          : saldo - t.value;
    });
  }

  Future<void> _onLoad(
      LoadTransactionsEvent event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());
    try {
      await emit.forEach(
        repository.getAll(event.userId),
        onData: (transactions) => TransactionSuccess(
          transactions: transactions,
          saldo: _calcularSaldo(transactions),
        ),
        onError: (_, _) =>
        const TransactionError('Erro ao carregar transações.'),
      );
    } catch (e) {
      emit(const TransactionError('Erro ao carregar transações.'));
    }
  }

  Future<void> _onAdd(
      AddTransactionEvent event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());
    try {
      await repository.save(event.transaction);
      await emit.forEach(
        repository.getAll(event.transaction.userId),
        onData: (transactions) => TransactionSuccess(
          transactions: transactions,
          saldo: _calcularSaldo(transactions),
        ),
        onError: (_, _) =>
        const TransactionError('Erro ao salvar transação.'),
      );
    } catch (e) {
      emit(const TransactionError('Erro ao salvar transação.'));
    }
  }

  Future<void> _onDelete(
      DeleteTransactionEvent event,
      Emitter<TransactionState> emit,
      ) async {
    emit(TransactionLoading());
    try {
      await repository.delete(event.transactionId, event.userId);
      await emit.forEach(
        repository.getAll(event.userId),
        onData: (transactions) => TransactionSuccess(
          transactions: transactions,
          saldo: _calcularSaldo(transactions),
        ),
        onError: (_, _) =>
        const TransactionError('Erro ao deletar transação.'),
      );
    } catch (e) {
      emit(const TransactionError('Erro ao deletar transação.'));
    }
  }
}