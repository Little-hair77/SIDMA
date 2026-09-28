import 'package:flutter/material.dart';
import 'cores.dart';

/// Monta o ThemeData completo (claro ou escuro) a partir de uma paleta
/// [AppColors].
ThemeData _construirTema(AppColors cores, Brightness brilho) {
  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    scaffoldBackgroundColor: cores.fundo,
    colorScheme: ColorScheme.fromSeed(
      seedColor: cores.primario,
      brightness: brilho,
      primary: cores.primario,
      surface: cores.superficie,
      error: cores.erro,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cores.destaque,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardColor: cores.superficie,
    dividerColor: cores.borda,
    extensions: [cores],
  );
}

final ThemeData temaClaro = _construirTema(AppColors.claro, Brightness.light);
final ThemeData temaEscuro = _construirTema(AppColors.escuro, Brightness.dark);