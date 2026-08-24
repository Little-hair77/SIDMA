import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import './views/splash.dart';

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
      debugShowCheckedModeBanner: false,
      title: 'SIDMA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D6EFD)),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        useMaterial3: true,
      ),
      home: const TelaSplash(),
    );
  }
}