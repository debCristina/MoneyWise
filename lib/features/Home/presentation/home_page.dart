//Ele importa o “kit visual” do Flutter.
import 'package:flutter/material.dart';

//criando uma tela chamada HomePage.
class HomePage extends StatelessWidget {

  // 	const  melhora performance
  // 	super.key  identifica o widget na árvore do Flutter
  const HomePage({super.key});

  // sempre que o Flutter precisa desenhar a página, ele chama esse metodo
  // contexto : onde essa tela está dentro do app
  @override
  Widget build(BuildContext context) {
    // Scaffold é uma classe que permite utilizar vários recursos do flutter
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Bem-vindo de volta"),
      ),
    );
  }
}
