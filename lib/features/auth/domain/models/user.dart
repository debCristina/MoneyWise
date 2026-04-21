class User {
  final String id;
  final String nome;
  final String email;

  const User({
    required this.id,
    required this.nome,
    required this.email,
  });

  /// Cria uma instância de User a partir de um Map (ex: do Firestore)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  /// Converte a instância de User para um Map para salvar no Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
    };
  }
}