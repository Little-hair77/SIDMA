import 'package:flutter/material.dart';
import 'dart:typed_data'; 
import '../core/cores.dart'; 
import '../core/usuario_estado.dart'; 
import '../views/dashboard.dart';
import '../views/animais.dart';
import '../views/historico.dart';
import '../views/pefil_usuario.dart'; 
import '../views/captura.dart';

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
      
      // BOTÃO CENTRAL FLUTUANTE (DIAGNÓSTICO IA)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 76, 
        height: 76, 
        margin: const EdgeInsets.only(top: 24), 
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelaCaptura()),
            );
          },
          backgroundColor: const Color.fromARGB(255, 29, 177, 86),
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(), 
          child: const Icon(Icons.document_scanner_outlined, size: 34), 
        ),
      ),
      
      // BARRA INFERIOR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), 
        notchMargin: 8.0, 
        color: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildTabItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Início', index: 0),
            _buildTabItem(icon: Icons.pets_outlined, selectedIcon: Icons.pets, label: 'Rebanho', index: 1),
            
            const SizedBox(width: 48), 
            
            _buildTabItem(icon: Icons.history_outlined, selectedIcon: Icons.history, label: 'Histórico', index: 2),
            _buildPerfilTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
  }) {
    final isSelected = _indiceAtual == index;
    return InkWell(
      onTap: () => setState(() => _indiceAtual = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon, 
              color: isSelected ? AppColors.azulPrincipal : Colors.grey.shade500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.azulPrincipal : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerfilTab() {
    final isSelected = _indiceAtual == 3;
    
    return InkWell(
      onTap: () => setState(() => _indiceAtual = 3),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<Uint8List?>(
              valueListenable: UsuarioEstado.fotoPerfilNotifier,
              builder: (context, fotoBytes, child) {
                if (fotoBytes != null) {
                  return CircleAvatar(
                    radius: 12,
                    backgroundColor: isSelected ? AppColors.azulPrincipal : Colors.transparent,
                    child: CircleAvatar(
                      radius: isSelected ? 10 : 12, 
                      backgroundImage: MemoryImage(fotoBytes),
                    ),
                  );
                }
                return Icon(
                  isSelected ? Icons.person : Icons.person_outline, 
                  color: isSelected ? AppColors.azulPrincipal : Colors.grey.shade500,
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.azulPrincipal : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}