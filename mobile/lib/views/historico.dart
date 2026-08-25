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
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86); 
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
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

  // - LÓGICA DE AGRUPAMENTO POR MÊS/ANO 
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
      
      // APP BAR 
      appBar: AppBar(
        backgroundColor: corVerdeEscuro,
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
      
      // MARCA D'ÁGUA
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
                              // - CABEÇALHO DO GRUPO (MÊS)
                              Padding(
                                padding: const EdgeInsets.only(top: 16, bottom: 12),
                                child: Text(
                                  mesChave,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 10, 51, 187), 
                                  ),
                                ),
                              ),
                              // - LISTA DE ITENS DO MÊS
                              ...analisesDoMes.map((a) => GestureDetector(
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => TelaDetalheAnalise(analiseId: a['id'])),
                                  );
                                  _carregar(); 
                                },
                                child: _CartaoHistoricoDetalhado(analise: a),
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

// WIDGET ESTADO VAZIO
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

// CARTÃO DE HISTÓRICO
class _CartaoHistoricoDetalhado extends StatelessWidget {
  final dynamic analise;

  const _CartaoHistoricoDetalhado({required this.analise});

  // - CORES PARA A DIV INTEIRA 
  Map<String, dynamic> get _statusConfig {
    final resultado = (analise['resultado']?.toString() ?? '').toLowerCase();
    
    if (resultado.contains('possível') || resultado.contains('suspeita') || resultado.contains('mastite')) {
      return {
        'corFundo': Colors.redAccent.shade400, 
        'icone': Icons.error_outline,
        'label': 'Suspeita Detectada'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corFundo': Colors.orange.shade600, 
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção Necessária'
      };
    } else {
      return {
        'corFundo': const Color.fromARGB(255, 29, 177, 86), // Verde Escuro do App
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
    
    // Tratamento seguro da URL
    final String imageUrl = analise['imagem_url']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: corBase, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: corBase.withOpacity(0.4), 
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail da Imagem com borda branca para destacar no fundo colorido
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 2), 
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 76,
                      height: 76,
                      color: Colors.white.withOpacity(0.2),
                      child: const Icon(Icons.science, color: Colors.white, size: 32),
                    ),
                  )
                : Container(
                    width: 76,
                    height: 76,
                    color: Colors.white.withOpacity(0.2),
                    child: const Icon(Icons.science, color: Colors.white, size: 32),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Dados Textuais (Tudo em Branco)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status em texto e ícone
                    Expanded(
                      child: Row(
                        children: [
                          Icon(config['icone'], size: 18, color: Colors.white),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              config['label'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white, 
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white70, size: 24),
                  ],
                ),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Colors.white30, height: 1, thickness: 1),
                ),
                
                Text(
                  'Confiança: ${analise['confianca'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 15, 
                    color: Colors.white, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      _formatarDataHora(analise['criado_em']),
                      style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}