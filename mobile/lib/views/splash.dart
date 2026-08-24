import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login.dart';
import '../navigation/nav.dart';

class TelaSplash extends StatefulWidget {
  const TelaSplash({Key? key}) : super(key: key);

  @override
  State<TelaSplash> createState() => _TelaSplashState();
}

class _TelaSplashState extends State<TelaSplash> with SingleTickerProviderStateMixin {
  static const Color corFundo = Color(0xFFF8FAFC);

  late final AnimationController _controller;
  late final Animation<double> _opacidade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _opacidade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _decidirProximaTela();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decidirProximaTela() async {
    final apiService = ApiService();

    // Garante um tempo mínimo de exibição da splash, mesmo em conexões rápidas,
    // para a marca não "piscar" na tela.
    final resultados = await Future.wait([
      apiService.estaLogado(),
      Future.delayed(const Duration(milliseconds: 1600)),
    ]);

    final logado = resultados[0] as bool;

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => logado ? const TelaPrincipal() : const TelaLogin()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: Center(
        child: FadeTransition(
          opacity: _opacidade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logoSIDMA-2.png',
                height: 120,
                errorBuilder: (_, __, ___) => const Icon(Icons.local_hospital, size: 100, color: Color(0xFF0D6EFD)),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0D6EFD)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}