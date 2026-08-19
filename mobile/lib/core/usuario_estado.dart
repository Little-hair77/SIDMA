import 'dart:typed_data';
import 'package:flutter/material.dart';

class UsuarioEstado {
  //ValueNotifier avisa a todos os ouvintes (como a NavBar) quando seu valor muda
  static final ValueNotifier<Uint8List?> fotoPerfilNotifier = ValueNotifier<Uint8List?>(null);

  // Função para atualizar a foto globalmente
  static void atualizarFoto(Uint8List? novosBytes) {
    fotoPerfilNotifier.value = novosBytes;
  }

  // Função para remover a foto globalmente
  static void removerFoto() {
    fotoPerfilNotifier.value = null;
  }
}