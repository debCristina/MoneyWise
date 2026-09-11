import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../logic/bloc/auth_bloc.dart';

// 1. O Widget (A parte "pública" que o Flutter usa para montar a árvore)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// 2. O Estado (A parte "privada" onde você controla o que acontece na tela)
class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Wise - Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            debugPrint('LOGIN PAGE: Estado recebido: $state');

            if (state is AuthSuccess) {
              debugPrint(
                'LOGIN PAGE: AuthSuccess - navegando para Home',
              );

              context.go('/home');
            } else if (state is AuthError) {
              debugPrint(
                'LOGIN PAGE: AuthError: ${state.message}',
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                  ),
                ),
                TextField(
                  controller: _senhaController,
                  decoration: const InputDecoration(
                    labelText: 'Senha',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          context.read<AuthBloc>().add(
                                LoginRequested(
                                  email: _emailController.text,
                                  password: _senhaController.text,
                                ),
                              );
                        },
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Entrar'),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    context.push('/cadastro');
                  },
                  child: const Text(
                    'Não tem uma conta? Cadastre-se',
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}