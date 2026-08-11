import 'package:flutter/material.dart';
import './services/api_service.dart';
import './views/tela_login.dart';
import './views/tela_captura.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIDMA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TelaInicial(),
    );
  }
}

// Decide, ao abrir o app, se o usuário já está logado (vai direto para a captura)

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return FutureBuilder<bool>(
      future: apiService.estaLogado(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final logado = snapshot.data ?? false;
        return logado ? const TelaCaptura() : const TelaLogin();
      },
    );
  }
}