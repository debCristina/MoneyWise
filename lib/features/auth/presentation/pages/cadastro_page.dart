//Ele importa o “kit visual” do Flutter.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:money_wise/features/auth/logic/bloc/auth_bloc.dart';

//criando uma tela chamada HomePage.
class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});
  // 	const  melhora performance
  // 	super.key  identifica o widget na árvore do Flutter

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  void dispose() {
    // limpa os controllers quando a tela fechar
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // sempre que o Flutter precisa desenhar a página, ele chama esse metodo
  // contexto : onde essa tela está dentro do app
  @override
  Widget build(BuildContext context) {
    // Scaffold é uma classe que permite utilizar vários recursos do flutter
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text("Criar nova conta")
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state){
            if(state is AuthSuccess){
              context.go('/home');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message),backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state){
            final isLoading = state is AuthLoading;
            return Column(
              children: [
                TextField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                TextField(
                  controller: _senhaController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : () {
                    context.read<AuthBloc>().add(
                      CadastroRequested(
                          nome: _nomeController.text,
                          email: _emailController.text,
                          password: _senhaController.text),
                    );
                  },
                  child: isLoading
                      ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)
                  )
                      : const Text('Cadastrar'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
