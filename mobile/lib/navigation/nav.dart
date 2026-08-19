import 'package:flutter/material.dart';
import 'dart:typed_data'; 
import '../core/cores.dart'; 
import '../core/usuario_estado.dart'; 
import '../views/dashboard.dart';
import '../views/animais.dart';
import '../views/historico.dart';
import '../views/pefil_usuario.dart'; 

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({Key? key}) : super(key: key);

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;

  final List<Widget> _telas = const [
    TelaDashboard(),
    TelaAnimais(),
    TelaHistorico(),
    TelaPerfilUsuario(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _indiceAtual,
          onDestinationSelected: (int novoIndice) {
            setState(() => _indiceAtual = novoIndice);
          },
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.azulPrincipal.withOpacity(0.12),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home),
              selectedIcon: Icon(Icons.home, color: AppColors.azulPrincipal),
              label: 'Início',
            ),
            const NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets, color: AppColors.azulPrincipal),
              label: 'Rebanho',
            ),
            const NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: AppColors.azulPrincipal),
              label: 'Histórico',
            ),
            
            // --- ABA DINÂMICA DO PERFIL ---
            NavigationDestination(
              icon: ValueListenableBuilder<Uint8List?>(
                valueListenable: UsuarioEstado.fotoPerfilNotifier,
                builder: (context, fotoBytes, child) {
                  if (fotoBytes != null) {
                    return CircleAvatar(
                      radius: 12, 
                      backgroundImage: MemoryImage(fotoBytes),
                    );
                  }
                  return const Icon(Icons.person_outline);
                },
              ),
              selectedIcon: ValueListenableBuilder<Uint8List?>(
                valueListenable: UsuarioEstado.fotoPerfilNotifier,
                builder: (context, fotoBytes, child) {
                  if (fotoBytes != null) {
                    return CircleAvatar(
                      radius: 12,
                      backgroundColor: AppColors.azulPrincipal,
                      child: CircleAvatar(
                        radius: 10, // Cria uma pequena borda azul de destaque ao redor da foto selecionada
                        backgroundImage: MemoryImage(fotoBytes),
                      ),
                    );
                  }
                  return const Icon(Icons.person, color: AppColors.azulPrincipal);
                },
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}