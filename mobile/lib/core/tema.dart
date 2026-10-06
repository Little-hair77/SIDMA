import 'package:flutter/material.dart';
import 'cores.dart';

/// [AppColors].
ThemeData _construirTema(AppColors cores, Brightness brilho) {
  final bool escuro = brilho == Brightness.dark;

  final ColorScheme esquema = ColorScheme.fromSeed(
    seedColor: cores.primario,
    brightness: brilho,
    primary: cores.primario,
    surface: cores.superficie,
    error: cores.erro,
  ).copyWith(
    onPrimary: Colors.white, 
    onSurface: cores.textoPrimario,
    onSurfaceVariant: cores.textoSecundario,
    surfaceContainerLowest: cores.fundo,
    surfaceContainerLow: cores.superficie,
    surfaceContainer: cores.superficie,
    surfaceContainerHigh: cores.superficie,
    surfaceContainerHighest: cores.superficieAlt,
    outlineVariant: cores.borda,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brilho,
    scaffoldBackgroundColor: cores.fundo,
    colorScheme: esquema,
    appBarTheme: AppBarTheme(
      backgroundColor: cores.destaque,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    // O texto padrão do SnackBar é "onInverseSurface", que no escuro é um tom
    // escuro. Como os snackbars do app têm fundo colorido (verde/vermelho),
    // o texto fica sempre branco.
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: const TextStyle(color: Colors.white),
      backgroundColor: escuro ? cores.superficieAlt : null,
    ),
    cardColor: cores.superficie,
    dividerColor: cores.borda,
    extensions: [cores],
  );
}

final ThemeData temaClaro = _construirTema(AppColors.claro, Brightness.light);
final ThemeData temaEscuro = _construirTema(AppColors.escuro, Brightness.dark);