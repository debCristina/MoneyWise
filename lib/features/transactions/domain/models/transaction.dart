enum TransactionType { despesa, receita }

class Transaction {
  final String id;
  final String userId;
  final double value;
  final DateTime data;
  final String category;
  final TransactionType type;

  const Transaction({
    required this.id,
    required this.userId,
    required this.value,
    required this.data,
    required this.category,
    required this.type,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final TransactionType tipo;

    switch (typeStr) {
      case 'despesa':
        tipo = TransactionType.despesa;
        break;
      case 'receita':
        tipo = TransactionType.receita;
        break;
      default:
        throw ArgumentError('Tipo de transação inválido: "$typeStr"');
    }

    final dataRaw = json['data'];
    final DateTime dataConvertida;

    // Suporta DateTime direto (testes) ou Timestamp do Firestore
    if (dataRaw is DateTime) {
      dataConvertida = dataRaw;
    } else {
      // Firestore Timestamp tem o método .toDate()
      dataConvertida = (dataRaw as dynamic).toDate() as DateTime;
    }

    return Transaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      value: (json['value'] as num).toDouble(),
      data: dataConvertida,
      category: json['category'] as String,
      type: tipo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'value': value,
      'data': data,
      'category': category,
      'type': type.name, // 'despesa' ou 'receita'
    };
  }
}
 