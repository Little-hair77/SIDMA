import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import './views/splash.dart';
import './core/tema.dart';
import './core/tema_estado.dart';

void main() async {
  // Garante que os widgets do Flutter estejam prontos antes de rodar comandos assíncronos
  WidgetsFlutterBinding.ensureInitialized();
  // Carrega os dados da data/hora em Português Brasil
  await initializeDateFormatting('pt_BR', null);
  // Carrega a preferência de aparência salva (claro/escuro/sistema)
  await TemaEstado.carregar();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ouve TemaEstado.modoNotifier: quando qualquer tela chamar
    // TemaEstado.definirModo(...), o app inteiro troca de aparência na hora,
    // sem precisar reiniciar.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: TemaEstado.modoNotifier,
      builder: (context, modoAtual, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SIDMA',
          theme: temaClaro,
          darkTheme: temaEscuro,
          themeMode: modoAtual,
          home: const TelaSplash(),
        );
      },
    );
  }
}