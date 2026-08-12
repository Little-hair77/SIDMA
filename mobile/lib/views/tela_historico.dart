import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({Key? key}) : super(key: key);

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final ApiService _apiService = ApiService();
  List<dynamic> _analises = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final historico = await _apiService.buscarHistorico();
    setState(() {
      _analises = historico ?? [];
      _carregando = false;
    });
  }

  Color _corResultado(String resultado) {
    if (resultado.contains('Possível')) return Colors.red;
    if (resultado.contains('adicional')) return Colors.orange;
    return Colors.green;
  }

  String _formatarData(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Histórico de Análises'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _analises.isEmpty
              ? const Center(
                  child: Text('Nenhuma análise encontrada.', style: TextStyle(color: Colors.grey)),
                )
              : RefreshIndicator(
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _analises.length,
                    itemBuilder: (context, index) {
                      final a = _analises[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                a['imagem_url'],
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    a['resultado'],
                                    style: TextStyle(fontWeight: FontWeight.bold, color: _corResultado(a['resultado'])),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Confiança: ${a['confianca']}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(_formatarData(a['criado_em']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}