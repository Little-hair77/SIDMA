import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalhe_animal.dart';

class TelaAlertas extends StatefulWidget {
  const TelaAlertas({Key? key}) : super(key: key);

  @override
  State<TelaAlertas> createState() => _TelaAlertasState();
}

class _TelaAlertasState extends State<TelaAlertas> {
  final ApiService _apiService = ApiService();

  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);
  static const Color corVerdePrincipal = Color(0xFF74C319);

  List<dynamic> _alertas = [];
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAlertas();
  }

  Future<void> _carregarAlertas() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    final alertas = await _apiService.listarAlertas();

    if (!mounted) return;

    setState(() {
      _carregando = false;
      if (alertas == null) {
        _erro = 'Não foi possível carregar os alertas. Puxe para tentar novamente.';
      } else {
        _alertas = alertas;
      }
    });
  }

  Future<void> _resolverAlerta(dynamic alerta) async {
    final sucesso = await _apiService.resolverAlerta(alerta['id']);
    if (!sucesso) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível resolver o alerta. Tente novamente.')),
      );
      return;
    }
    setState(() => _alertas.removeWhere((a) => a['id'] == alerta['id']));
  }

  Future<void> _abrirDetalheAnimal(int animalId) async {
    // O objeto 'animal' embutido no alerta só tem id/brinco/nome — busca os
    // dados completos antes de abrir a tela de detalhe.
    final animalCompleto = await _apiService.buscarAnimal(animalId);
    if (!mounted) return;

    if (animalCompleto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir os detalhes do animal.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animalCompleto)),
    );
  }

  ({IconData icone, Color cor}) _estiloPorTipo(String? tipo) {
    switch (tipo) {
      case 'REINCIDENCIA':
        return (icone: Icons.repeat, cor: Colors.redAccent);
      case 'CARENCIA':
        return (icone: Icons.medical_information_outlined, cor: Colors.blueAccent);
      case 'CIO':
        return (icone: Icons.favorite_border, cor: Colors.pinkAccent);
      case 'CCS_ELEVADO':
        return (icone: Icons.science_outlined, cor: Colors.deepOrange);
      default:
        return (icone: Icons.notifications_outlined, cor: Colors.grey);
    }
  }

  String _formatarData(String? dataIso) {
    final data = DateTime.tryParse(dataIso ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corFundo,
        elevation: 0,
        iconTheme: const IconThemeData(color: corTextoPrimario),
        title: Row(
          children: [
            const Text('Alertas', style: TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold)),
            if (_alertas.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                child: Text('${_alertas.length}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
      body: _construirCorpo(),
    );
  }

  Widget _construirCorpo() {
    if (_carregando) return const Center(child: CircularProgressIndicator());

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_erro!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _carregarAlertas, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    if (_alertas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarAlertas,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 120.0, horizontal: 32.0),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: corVerdePrincipal.withOpacity(0.6)),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum alerta ativo no momento.\nSeu rebanho está em dia!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarAlertas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alertas.length,
        itemBuilder: (contexto, indice) => _construirCartaoAlerta(_alertas[indice]),
      ),
    );
  }

  Widget _construirCartaoAlerta(dynamic alerta) {
    final estilo = _estiloPorTipo(alerta['tipo']);
    final animal = alerta['animal'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: estilo.cor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: animal == null
            ? null
            : () => _abrirDetalheAnimal(animal['id']),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: estilo.cor.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(estilo.icone, color: estilo.cor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alerta['tipo_display'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: estilo.cor),
                        ),
                      ),
                      if (animal != null)
                        Text('#${animal['brinco']}', style: const TextStyle(color: Colors.black45, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(alerta['mensagem'] ?? '', style: const TextStyle(color: corTextoPrimario, fontSize: 13, height: 1.3)),
                  const SizedBox(height: 6),
                  Text(_formatarData(alerta['criado_em']), style: const TextStyle(color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Marcar como resolvido',
              icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
              onPressed: () => _resolverAlerta(alerta),
            ),
          ],
        ),
      ),
    );
  }
}