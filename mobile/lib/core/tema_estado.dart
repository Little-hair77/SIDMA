import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TemaEstado {
  static const _chave = 'tema_modo_preferido';
  static const _storage = FlutterSecureStorage();

  /// Ouvido pelo MaterialApp em main.dart para trocar o tema em tempo real.
  static final ValueNotifier<ThemeMode> modoNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

  /// Carrega a preferência salva. Chamado uma única vez, no main(), antes do runApp.
  static Future<void> carregar() async {
    final salvo = await _storage.read(key: _chave);
    switch (salvo) {
      case 'claro':
        modoNotifier.value = ThemeMode.light;
        break;
      case 'escuro':
        modoNotifier.value = ThemeMode.dark;
        break;
      default:
        // Nunca configurado: segue o tema do sistema.
        modoNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> definirModo(ThemeMode novoModo) async {
    modoNotifier.value = novoModo;
    final valor = switch (novoModo) {
      ThemeMode.light => 'claro',
      ThemeMode.dark => 'escuro',
      ThemeMode.system => 'sistema',
    };
    await _storage.write(key: _chave, value: valor);
  }
}