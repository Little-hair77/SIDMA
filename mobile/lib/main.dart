import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import './services/api_service.dart';
import 'views/login.dart';
import 'views/dashboard.dart';

void main() async {
  // Garante que os widgets do Flutter estejam prontos antes de rodar comandos assíncronos
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega os dados da data/hora em Português Brasil
  await initializeDateFormatting('pt_BR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIDMA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6EFD)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
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
        return logado ? const TelaDashboard() : const TelaLogin();
      },
    );
  }
}