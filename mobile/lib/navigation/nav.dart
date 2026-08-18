import 'package:flutter/material.dart';
import '../core/cores.dart'; 
import '../views/dashboard.dart';
import '../views/animais.dart';
import '../views/historico.dart';

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({Key? key}) : super(key: key);

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _indiceAtual = 0;

  // Lista com as telas que farão parte do fluxo principal
  final List<Widget> _telas = const [
    TelaDashboard(),
    TelaAnimais(),
    TelaHistorico(),
    _TelaPerfilPlaceholder(), // Provisório até criar a tela final
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      
      // IndexedStack preserva o estado de rolagem e dados de cada aba
      body: IndexedStack(
        index: _indiceAtual,
        children: _telas,
      ),

      // NavigationBar do Material 3 estilizada profissionalmente
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _indiceAtual,
          onDestinationSelected: (int novoIndice) {
            setState(() {
              _indiceAtual = novoIndice;
            });
          },
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: AppColors.azulPrincipal.withOpacity(0.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home),
              selectedIcon: Icon(Icons.home, color: AppColors.azulPrincipal),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(Icons.pets, color: AppColors.azulPrincipal),
              label: 'Rebanho',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: AppColors.azulPrincipal),
              label: 'Histórico',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.azulPrincipal),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

// Widget de suporte temporário para a aba de Perfil
class _TelaPerfilPlaceholder extends StatelessWidget {
  const _TelaPerfilPlaceholder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.fundo,
      body: Center(
        child: Text(
          'Perfil do Usuário em Desenvolvimento',
          style: TextStyle(color: AppColors.textoPrimario, fontSize: 16),
        ),
      ),
    );
  }
}