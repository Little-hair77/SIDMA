import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
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

  // DEFINIÇÃO DA PALETA DE CORES (IDÊNTICA AO DASHBOARD)
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
    
    // Opcional: Garantir que a lista venha ordenada da mais recente para a mais antiga
    if (historico != null) {
      historico.sort((a, b) {
        DateTime dataA = DateTime.tryParse(a['criado_em'] ?? '') ?? DateTime.now();
        DateTime dataB = DateTime.tryParse(b['criado_em'] ?? '') ?? DateTime.now();
        return dataB.compareTo(dataA);
      });
    }

    setState(() {
      _analises = historico ?? [];
      _carregando = false;
    });
  }

  // --- LÓGICA DE AGRUPAMENTO POR MÊS/ANO ---
  Map<String, List<dynamic>> _agruparAnalises() {
    Map<String, List<dynamic>> mapaAgrupado = {};
    
    for (var analise in _analises) {
      DateTime data = DateTime.tryParse(analise['criado_em'] ?? '') ?? DateTime.now();
      // Formata como "Mês Ano" (ex: "Agosto 2026")
      String mesAno = DateFormat('MMMM yyyy', 'pt_BR').format(data);
      // Capitaliza a primeira letra do mês
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
    // Agrupa os dados antes de renderizar
    final analisesAgrupadas = _agruparAnalises();

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: corAzulPrincipal),
        title: const Text(
          'Histórico Completo',
          style: TextStyle(
            color: corTextoPrimario,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
          : _analises.isEmpty
              ? _ConstruirEstadoVazio()
              : RefreshIndicator(
                  color: corAzulPrincipal,
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: analisesAgrupadas.length,
                    itemBuilder: (context, index) {
                      // Extrai a chave (Mês/Ano) e a lista de análises correspondente
                      String mesChave = analisesAgrupadas.keys.elementAt(index);
                      List<dynamic> analisesDoMes = analisesAgrupadas[mesChave]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- CABEÇALHO DO GRUPO (MÊS) ---
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 12),
                            child: Text(
                              mesChave,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: corAzulPrincipal,
                              ),
                            ),
                          ),
                          // --- LISTA DE ITENS DO MÊS ---
                          ...analisesDoMes.map((a) => _CartaoHistoricoDetalhado(analise: a)).toList(),
                        ],
                      );
                    },
                  ),
                ),
    );
  }
}

// ============================================================================
// WIDGET ESTADO VAZIO (PROFISSIONAL)
// ============================================================================
class _ConstruirEstadoVazio extends StatelessWidget {
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

// ============================================================================
// CARTÃO DE HISTÓRICO (REUTILIZANDO A LÓGICA DE STATUS DO DASHBOARD)
// ============================================================================
class _CartaoHistoricoDetalhado extends StatelessWidget {
  final dynamic analise;

  const _CartaoHistoricoDetalhado({required this.analise});

  Map<String, dynamic> get _statusConfig {
    final resultado = (analise['resultado'] as String).toLowerCase();
    
    if (resultado.contains('possível') || resultado.contains('suspeita') || resultado.contains('mastite')) {
      return {
        'corTexto': Colors.red.shade700,
        'corFundo': Colors.red.shade50,
        'icone': Icons.error_outline,
        'label': 'Suspeita'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corTexto': Colors.orange.shade800,
        'corFundo': Colors.orange.shade50,
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção'
      };
    } else {
      return {
        'corTexto': Colors.green.shade700,
        'corFundo': Colors.green.shade50,
        'icone': Icons.check_circle_outline,
        'label': 'Saudável'
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinha os itens no topo
        children: [
          // Thumbnail da Imagem (um pouco maior que no dashboard)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                analise['imagem_url'] ?? '',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade50,
                  child: Icon(Icons.science, color: Colors.grey.shade300, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Dados Textuais e Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge de Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: config['corFundo'],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(config['icone'], size: 14, color: config['corTexto']),
                          const SizedBox(width: 4),
                          Text(
                            config['label'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: config['corTexto'],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Opcional: ID da Vaca/Brinco se você adicionar isso no futuro
                    // Text('#Brinco: 104', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Confiança: ${analise['confianca'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14, 
                    color: _TelaHistoricoState.corTextoPrimario, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      _formatarDataHora(analise['criado_em']),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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