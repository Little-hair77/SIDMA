import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'alertas.dart';

class BotaoSinoAlertas extends StatefulWidget {
  final Color corIcone;

  const BotaoSinoAlertas({Key? key, this.corIcone = Colors.black87}) : super(key: key);

  @override
  State<BotaoSinoAlertas> createState() => _BotaoSinoAlertasState();
}

class _BotaoSinoAlertasState extends State<BotaoSinoAlertas> {
  final ApiService _apiService = ApiService();
  int _quantidade = 0;

  @override
  void initState() {
    super.initState();
    _carregarQuantidade();
  }

  Future<void> _carregarQuantidade() async {
    final alertas = await _apiService.listarAlertas();
    if (!mounted || alertas == null) return;
    setState(() => _quantidade = alertas.length);
  }

  Future<void> _abrirAlertas() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TelaAlertas()),
    );
    // Ao voltar da tela de alertas, atualiza o contador (o usuário pode ter
    // resolvido algum alerta lá dentro).
    _carregarQuantidade();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _abrirAlertas,
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(Icons.notifications_outlined, color: widget.corIcone, size: 28),
            if (_quantidade > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                  child: Text(
                    _quantidade > 9 ? '9+' : '$_quantidade',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}