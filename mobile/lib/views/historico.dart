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

  // Paleta de Cores
  static const Color corVerdePrimaria   = Color(0xFF10B981); 
  static const Color corAzulMarinho     = Color(0xFF1E293B); 
  static const Color corTextoPrimario   = Color(0xFF0F172A); 
  static const Color corTextoSecundario = Color(0xFF64748B); 
  static const Color corFundo           = Color(0xFFF8FAFC); 
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
      
      // APP BAR INSTITUCIONAL
      appBar: AppBar(
        backgroundColor: corAzulMarinho,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico Completo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      
      body: Stack(
        children: [
          // MARCA D'ÁGUA SUAVE
          Center(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/logoSIDMA-2.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 200, color: Colors.grey.shade400),
              ),
            ),
          ),
          
          _carregando
              ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
              : _analises.isEmpty
                  ? const _ConstruirEstadoVazio()
                  : RefreshIndicator(
                      color: corVerdePrimaria,
                      onRefresh: _carregar,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        itemCount: analisesAgrupadas.length,
                        itemBuilder: (context, index) {
                          String mesChave = analisesAgrupadas.keys.elementAt(index);
                          List<dynamic> analisesDoMes = analisesAgrupadas[mesChave]!;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                                child: Text(
                                  mesChave,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: corAzulMarinho, 
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
          Icon(Icons.history_toggle_off_outlined, size: 64, color: const Color(0xFF64748B).withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'Histórico Vazio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'As análises concluídas aparecerão aqui.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
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
        'corBorda': Colors.redAccent,
        'corFundoTag': Colors.red.shade50,
        'corTextoTag': Colors.red.shade700,
        'icone': Icons.error_outline,
        'label': 'Suspeita Detectada'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corBorda': Colors.amber.shade700,
        'corFundoTag': Colors.amber.shade50,
        'corTextoTag': Colors.amber.shade900,
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção Necessária'
      };
    } else {
      return {
        'corBorda': const Color(0xFF10B981),
        'corFundoTag': const Color(0xFF10B981).withOpacity(0.12),
        'corTextoTag': const Color(0xFF10B981),
        'icone': Icons.check_circle_outline,
        'label': 'Laudo Saudável'
      };
    }
  }

  String _formatarDataHora(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return 'Data desconhecida';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig;
    final String imageUrl = analise['imagem_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), 
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(color: config['corBorda'], width: 4),
          top: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          right: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
          bottom: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: aoClicar,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // MINIATURA DA FOTO
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1), 
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.science, color: Color(0xFF64748B), size: 28),
                        )
                      : const Icon(Icons.science, color: Color(0xFF64748B), size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                
                // INFORMAÇÕES PRINCIPAIS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BADGE DE STATUS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: config['corFundoTag'],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(config['icone'], size: 14, color: config['corTextoTag']),
                            const SizedBox(width: 4),
                            Text(
                              config['label'],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: config['corTextoTag'], 
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Confiança: ${analise['confianca'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontSize: 13, 
                          color: Color(0xFF0F172A), 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatarDataHora(analise['criado_em']),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}