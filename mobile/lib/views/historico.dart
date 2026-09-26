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
  bool _comErro = false;

  // Filtros (RF22)
  String? _filtroResultado; // null = todos os resultados
  DateTimeRange? _filtroPeriodo; // null = todo o período
  bool get _temFiltroAtivo => _filtroResultado != null || _filtroPeriodo != null;

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
    // Recarrega automaticamente quando uma nova análise é registrada em outra
    // tela (ex: botão flutuante central), já que esta tela fica "viva" dentro
    // do IndexedStack e não seria recriada ao voltar para essa aba.
    ApiService.notificadorAnalises.addListener(_aoNovaAnalise);
  }

  void _aoNovaAnalise() {
    if (mounted) _carregar();
  }

  @override
  void dispose() {
    ApiService.notificadorAnalises.removeListener(_aoNovaAnalise);
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _comErro = false;
    });

    final historico = _temFiltroAtivo
        ? await _apiService.buscarHistoricoFiltrado(
            resultado: _filtroResultado,
            dataInicio: _filtroPeriodo != null ? _formatarDataApi(_filtroPeriodo!.start) : null,
            dataFim: _filtroPeriodo != null ? _formatarDataApi(_filtroPeriodo!.end) : null,
          )
        : await _apiService.buscarHistorico();

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
      // null = falha na requisição (rede/autenticação); [] = sem análises mesmo. São coisas diferentes.
      _comErro = historico == null;
      _carregando = false;
    });
  }

  String _formatarDataApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatarDataBr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _rotuloResultado(String? valor) {
    switch (valor) {
      case 'Sem indícios de mastite':
        return 'Sem indícios';
      case 'Possível presença de mastite':
        return 'Possível mastite';
      case 'Necessária avaliação adicional':
        return 'Avaliação adicional';
      default:
        return 'Todos os resultados';
    }
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final escolhido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: agora,
      initialDateRange: _filtroPeriodo,
      helpText: 'Selecione o período',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: corVerdePrimaria, onPrimary: Colors.white, onSurface: corTextoPrimario),
          ),
          child: child!,
        );
      },
    );
    if (escolhido != null) {
      setState(() => _filtroPeriodo = escolhido);
      _carregar();
    }
  }

  /// Barra de filtro inline, no mesmo lugar/estilo de uma barra de busca:
  /// uma única caixa branca arredondada, dividida em duas áreas tocáveis
  /// (Resultado | Período), sem precisar abrir modal.
  Widget _buildBarraFiltros() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: PopupMenuButton<String?>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(0, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    setState(() => _filtroResultado = v);
                    _carregar();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: null, child: Text('Todos os resultados')),
                    PopupMenuItem(value: 'Sem indícios de mastite', child: Text('Sem indícios')),
                    PopupMenuItem(value: 'Possível presença de mastite', child: Text('Possível mastite')),
                    PopupMenuItem(value: 'Necessária avaliação adicional', child: Text('Avaliação adicional')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 18, color: _filtroResultado != null ? corVerdePrimaria : corTextoSecundario),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _rotuloResultado(_filtroResultado),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _filtroResultado != null ? FontWeight.w600 : FontWeight.normal,
                              color: _filtroResultado != null ? corVerdePrimaria : corTextoSecundario,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.expand_more, size: 18, color: corTextoSecundario),
                      ],
                    ),
                  ),
                ),
              ),
              const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              InkWell(
                onTap: _selecionarPeriodo,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.date_range_outlined, size: 18, color: _filtroPeriodo != null ? corVerdePrimaria : corTextoSecundario),
                      const SizedBox(width: 8),
                      Text(
                        _filtroPeriodo == null ? 'Período' : '${_formatarDataBr(_filtroPeriodo!.start)} – ${_formatarDataBr(_filtroPeriodo!.end)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _filtroPeriodo != null ? FontWeight.w600 : FontWeight.normal,
                          color: _filtroPeriodo != null ? corVerdePrimaria : corTextoSecundario,
                        ),
                      ),
                      if (_filtroPeriodo != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _filtroPeriodo = null);
                            _carregar();
                          },
                          child: const Icon(Icons.clear, size: 16, color: corTextoSecundario),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Linha discreta com a contagem de resultados e atalho para limpar,
  /// mostrada só quando algum filtro está ativo.
  Widget _buildBarraResumo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_analises.length} resultado(s) encontrado(s)',
              style: const TextStyle(fontSize: 12, color: corTextoSecundario),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _filtroResultado = null;
                _filtroPeriodo = null;
              });
              _carregar();
            },
            child: const Text('Limpar filtros', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corVerdePrimaria)),
          ),
        ],
      ),
    );
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
          
          Column(
            children: [
              _buildBarraFiltros(),
              if (_temFiltroAtivo && !_carregando) _buildBarraResumo(),
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
                    : _comErro
                        ? _ConstruirEstadoErro(aoTentarNovamente: _carregar)
                        : _analises.isEmpty
                        ? _ConstruirEstadoVazio(filtrado: _temFiltroAtivo)
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConstruirEstadoErro extends StatelessWidget {
  final VoidCallback aoTentarNovamente;
  const _ConstruirEstadoErro({Key? key, required this.aoTentarNovamente}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_outlined, size: 64, color: Colors.redAccent.withOpacity(0.6)),
            const SizedBox(height: 16),
            const Text(
              'Não foi possível carregar o histórico',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Verifique sua conexão com a internet e se o servidor está acessível.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: aoTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConstruirEstadoVazio extends StatelessWidget {
  final bool filtrado;
  const _ConstruirEstadoVazio({Key? key, this.filtrado = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filtrado ? Icons.filter_alt_off_outlined : Icons.history_toggle_off_outlined,
            size: 64,
            color: const Color(0xFF64748B).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filtrado ? 'Nenhum resultado para esse filtro' : 'Histórico Vazio',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          Text(
            filtrado
                ? 'Tente ajustar o resultado ou o período selecionado.'
                : 'As análises concluídas aparecerão aqui.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
        ),
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