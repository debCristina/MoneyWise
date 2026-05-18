import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:money_wise/features/transactions/domain/models/transaction.dart';

class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _userCollection(String userId) =>
      _firestore.collection('transactions').doc(userId).collection('transactions');

  // ── SAVE ──────────────────────────────────────────────────────────────────
  // Persiste em /transactions/{userId}/transactions/{id}
  // Funciona offline: o Firestore enfileira e sincroniza ao reconectar.

  Future<void> save(Transaction transaction) async {
    final data = transaction.toJson()
      ..remove('id')
      ..['data'] = Timestamp.fromDate(transaction.data);

    final col = _userCollection(transaction.userId);

    if (transaction.id.isEmpty) {
      await col.add(data);          // novo documento — id gerado pelo Firestore
    } else {
      await col.doc(transaction.id).set(data); // upsert — cria ou sobrescreve
    }
  }

  // ── GET ALL ───────────────────────────────────────────────────────────────
  // Stream reativo filtrado pelo path do userId.
  // Nunca retorna dados de outro usuário — o isolamento é estrutural (path).

  Stream<List<Transaction>> getAll(String userId) {
    return _userCollection(userId)
        .orderBy('data', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => Transaction.fromJson({
          ...doc.data(),
          'id': doc.id,
          'userId': userId,
        }),
      )
          .toList(),
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────
  // Remove só dentro do path do próprio usuário.

  Future<void> delete(String transactionId, String userId) async {
    await _userCollection(userId).doc(transactionId).delete();
  }
}