import 'package:flutter/material.dart';
import 'dart:typed_data'; 
import '../core/usuario_estado.dart'; 
import '../core/cores.dart';
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

  AppColors get _cores => AppColors.of(context);
  // Dark mode
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  // Paleta de Cores 
  Color get corVerdePrimaria => _cores.primario;
  Color get corFundo => _cores.fundo;

  Color get corSelecionado => _isDark ? _cores.primarioEscuro : _cores.destaque;
  Color get corCinzaInativo => _isDark ? _cores.textoSecundario : _cores.textoDesabilitado;

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
        decoration: BoxDecoration(
          // No escuro a sombra some, então uma linha fina separa a barra do conteúdo.
          border: Border(
            top: BorderSide(color: _isDark ? _cores.borda : Colors.transparent),
          ),
          boxShadow: const [
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
          color: _cores.superficie,
          surfaceTintColor: _cores.superficie,
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
              color: isSelected ? corSelecionado : corCinzaInativo,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? corSelecionado : corCinzaInativo,
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
                        color: isSelected ? corSelecionado : Colors.transparent,
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
                  color: isSelected ? corSelecionado : corCinzaInativo,
                );
              },
            ),
            const SizedBox(height: 3),
            Text(
              'Perfil',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? corSelecionado : corCinzaInativo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}