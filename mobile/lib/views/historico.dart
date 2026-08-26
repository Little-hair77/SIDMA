import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import '../services/api_service.dart';
import 'detalhe_analise.dart'; 

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({Key? key}) : super(key: key);

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final ApiService _apiService = ApiService();
  List<dynamic> _analises = [];
  bool _carregando = true;

  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86); 
  static const Color corVerdeClaro = Color(0xFF74C319);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final historico = await _apiService.buscarHistorico();
    
    if (historico != null) {
      historico.sort((a, b) {
        DateTime dataA = DateTime.tryParse(a['criado_em']?.toString() ?? '') ?? DateTime.now();
        DateTime dataB = DateTime.tryParse(b['criado_em']?.toString() ?? '') ?? DateTime.now();
        return dataB.compareTo(dataA);
      });
    }

    if (!mounted) return;
    setState(() {
      _analises = historico ?? [];
      _carregando = false;
    });
  }

  Map<String, List<dynamic>> _agruparAnalises() {
    Map<String, List<dynamic>> mapaAgrupado = {};
    
    for (var analise in _analises) {
      DateTime data = DateTime.tryParse(analise['criado_em']?.toString() ?? '') ?? DateTime.now();
      String mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(data);
      mesAno = mesAno[0].toUpperCase() + mesAno.substring(1);

      if (!mapaAgrupado.containsKey(mesAno)) {
        mapaAgrupado[mesAno] = [];
      }
      mapaAgrupado[mesAno]!.add(analise);
    }
    return mapaAgrupado;
  }

  @override
  Widget build(BuildContext context) {
    final analisesAgrupadas = _agruparAnalises();

    return Scaffold(
      backgroundColor: corFundo,
      
      appBar: AppBar(
        backgroundColor: corVerdeClaro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico Completo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
      ),
      
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.04, 
              child: Image.asset(
                'assets/images/logoSIDMA-2.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 200, color: Colors.grey.shade400),
              ),
            ),
          ),
          
          _carregando
              ? const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
              : _analises.isEmpty
                  ? const _ConstruirEstadoVazio()
                  : RefreshIndicator(
                      color: corVerdePrincipal,
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: analisesAgrupadas.length,
                        itemBuilder: (context, index) {
                          String mesChave = analisesAgrupadas.keys.elementAt(index);
                          List<dynamic> analisesDoMes = analisesAgrupadas[mesChave]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 12),
                                child: Text(
                                  mesChave,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: corVerdeEscuro, 
                                  ),
                                ),
                              ),
                              ...analisesDoMes.map((a) => _CartaoHistoricoDetalhado(
                                analise: a,
                                aoClicar: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TelaDetalheAnalise(analiseId: a['id'])),
                                  );
                                  _carregar(); 
                                },
                              )).toList(),
                            ],
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

class _ConstruirEstadoVazio extends StatelessWidget {
  const _ConstruirEstadoVazio({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Histórico Vazio',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'As análises concluídas aparecerão aqui.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _CartaoHistoricoDetalhado extends StatelessWidget {
  final dynamic analise;
  final VoidCallback aoClicar;

  const _CartaoHistoricoDetalhado({required this.analise, required this.aoClicar});

  Map<String, dynamic> get _statusConfig {
    final resultado = (analise['resultado']?.toString() ?? 'Desconhecido').toLowerCase();
    
    if (resultado.contains('possível') || resultado.contains('suspeita') || resultado.contains('mastite')) {
      return {
        'corFundo': const Color.fromARGB(190, 255, 0, 51), 
        'icone': Icons.error_outline,
        'label': 'Suspeita Detectada'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corFundo': const Color.fromARGB(190, 253, 200, 24), 
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção Necessária'
      };
    } else {
      return {
        'corFundo': const Color.fromARGB(190, 71, 190, 117),
        'icone': Icons.check_circle_outline,
        'label': 'Laudo Saudável'
      };
    }
  }

  String _formatarDataHora(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return 'Data desconhecida';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig;
    final corBase = config['corFundo'] as Color;
    final String imageUrl = analise['imagem_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: corBase.withOpacity(0.4), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: corBase,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoClicar,
          hoverColor: Colors.black12,
          splashColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54, width: 2), 
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.science, color: Colors.white, size: 32),
                        )
                      : const Icon(Icons.science, color: Colors.white, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(config['icone'], size: 20, color: Colors.white),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              config['label'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, 
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Confiança: ${analise['confianca'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 14, 
                          color: Colors.white, 
                          fontWeight: FontWeight.w600
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatarDataHora(analise['criado_em']),
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Icon(Icons.chevron_right, color: Colors.white70, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}