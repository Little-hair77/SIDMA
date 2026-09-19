import 'package:flutter/material.dart';
import 'dart:typed_data'; 
import '../core/usuario_estado.dart'; 
import '../views/dashboard.dart';
import '../views/animais.dart';
import '../views/historico.dart';
import '../views/perfil_usuario.dart'; 
import '../views/captura.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;

  // Paleta de Cores
  static const Color corVerdePrimaria = Color(0xFF10B981); 
  static const Color corAzulMarinho = Color(0xFF1E293B);   
  static const Color corCinzaInativo = Color(0xFF94A3B8);  
  static const Color corFundo = Color(0xFFF8FAFC);        

  final List<Widget> _telas = const [
    TelaDashboard(),
    TelaAnimais(),
    TelaHistorico(),
    TelaPerfilUsuario(), 
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),
      
      // BOTÃO CENTRAL FLUTUANTE (DIAGNÓSTICO IA)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        width: 68, 
        height: 68, 
        margin: const EdgeInsets.only(top: 18), 
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: corVerdePrimaria.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TelaCaptura()),
            );
          },
          backgroundColor: corVerdePrimaria,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 2,
          shape: const CircleBorder(), 
          child: const Icon(Icons.document_scanner_outlined, size: 30), 
        ),
      ),
      
      // BARRA INFERIOR 
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(), 
          notchMargin: 8.0, 
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(
                icon: Icons.grid_view_outlined, 
                selectedIcon: Icons.grid_view_rounded, 
                label: 'Início', 
                index: 0
              ),
              _buildTabItem(
                icon: Icons.agriculture_outlined, 
                selectedIcon: Icons.agriculture, 
                label: 'Rebanho', 
                index: 1
              ),
              
              const SizedBox(width: 48), 
              
              _buildTabItem(
                icon: Icons.history_outlined, 
                selectedIcon: Icons.history, 
                label: 'Histórico', 
                index: 2
              ),
              _buildPerfilTab(),
            ],
          ),
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
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon, 
              size: 22,
              color: isSelected ? corAzulMarinho : corCinzaInativo,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? corAzulMarinho : corCinzaInativo,
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
      borderRadius: BorderRadius.circular(12),
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
                  return Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? corAzulMarinho : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 10, 
                      backgroundImage: MemoryImage(fotoBytes),
                    ),
                  );
                }
                return Icon(
                  isSelected ? Icons.person : Icons.person_outline, 
                  size: 22,
                  color: isSelected ? corAzulMarinho : corCinzaInativo,
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? corAzulMarinho : corCinzaInativo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}