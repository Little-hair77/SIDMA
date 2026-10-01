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
  bool _usandoCacheOffline = false;

  // Filtros
  String? _filtroResultado;
  DateTimeRange? _filtroPeriodo;
  bool get _temFiltroAtivo => _filtroResultado != null || _filtroPeriodo != null;

  // Paleta de Cores 
  static const Color corVerdePrimaria   = Color(0xFF10B981);
  static const Color corAzulMarinho     = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
    // Recarrega automaticamente quando uma nova análise é registrada
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
    if (!mounted) return;
    
    setState(() {
      _carregando = true;
      _comErro = false;
    });

    var historico = _temFiltroAtivo
        ? await _apiService.buscarHistoricoFiltrado(
            resultado: _filtroResultado,
            dataInicio: _filtroPeriodo != null ? _formatarDataApi(_filtroPeriodo!.start) : null,
            dataFim: _filtroPeriodo != null ? _formatarDataApi(_filtroPeriodo!.end) : null,
          )
        : await _apiService.buscarHistorico();

    // Fallback de cache offline caso não haja conexão/servidor
    bool usandoCache = false;
    if (historico == null && !_temFiltroAtivo) {
      final cache = await _apiService.obterHistoricoCacheOffline();
      if (cache != null) {
        historico = cache;
        usandoCache = true;
      }
    }

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
      _comErro = historico == null;
      _usandoCacheOffline = usandoCache;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: corVerdePrimaria,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: corVerdePrimaria,
                    onPrimary: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
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

  Widget _buildBarraFiltros(bool isDark) {
    final colorTextoSecundario = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final colorCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final colorBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: colorCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorBorder),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: PopupMenuButton<String?>(
                  padding: EdgeInsets.zero,
                  offset: const Offset(0, 46),
                  color: colorCard,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    setState(() => _filtroResultado = v);
                    _carregar();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: null,
                      child: Text('Todos os resultados', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    PopupMenuItem(
                      value: 'Sem indícios de mastite',
                      child: Text('Sem indícios', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    PopupMenuItem(
                      value: 'Possível presença de mastite',
                      child: Text('Possível mastite', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                    PopupMenuItem(
                      value: 'Necessária avaliação adicional',
                      child: Text('Avaliação adicional', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search,
                          size: 18,
                          color: _filtroResultado != null ? corVerdePrimaria : colorTextoSecundario,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _rotuloResultado(_filtroResultado),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _filtroResultado != null ? FontWeight.w600 : FontWeight.normal,
                              color: _filtroResultado != null ? corVerdePrimaria : colorTextoSecundario,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.expand_more, size: 18, color: colorTextoSecundario),
                      ],
                    ),
                  ),
                ),
              ),
              VerticalDivider(width: 1, thickness: 1, color: colorBorder),
              InkWell(
                onTap: _selecionarPeriodo,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 18,
                        color: _filtroPeriodo != null ? corVerdePrimaria : colorTextoSecundario,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _filtroPeriodo == null
                            ? 'Período'
                            : '${_formatarDataBr(_filtroPeriodo!.start)} – ${_formatarDataBr(_filtroPeriodo!.end)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _filtroPeriodo != null ? FontWeight.w600 : FontWeight.normal,
                          color: _filtroPeriodo != null ? corVerdePrimaria : colorTextoSecundario,
                        ),
                      ),
                      if (_filtroPeriodo != null) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() => _filtroPeriodo = null);
                            _carregar();
                          },
                          child: Icon(Icons.clear, size: 16, color: colorTextoSecundario),
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

  Widget _buildBarraOffline(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF451A03) : const Color(0xFFFFFBEB),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 15, color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sem conexão — mostrando os últimos dados sincronizados.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraResumo(bool isDark) {
    final colorTextoSecundario = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_analises.length} resultado(s) encontrado(s)',
              style: TextStyle(fontSize: 12, color: colorTextoSecundario),
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
            child: const Text(
              'Limpar filtros',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corVerdePrimaria),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final corFundo = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final analisesAgrupadas = _agruparAnalises();

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF020617) : corAzulMarinho,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Histórico Completo',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: Stack(
        children: [
          // Marca d'água discreta
          Center(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.03,
              child: Image.asset(
                'assets/images/logoSIDMA-0.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 200, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
              ),
            ),
          ),
          Column(
            children: [
              _buildBarraFiltros(isDark),
              if (_usandoCacheOffline && !_carregando) _buildBarraOffline(isDark),
              if (_temFiltroAtivo && !_carregando) _buildBarraResumo(isDark),
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
                    : _comErro
                        ? _ConstruirEstadoErro(aoTentarNovamente: _carregar, isDark: isDark)
                        : _analises.isEmpty
                            ? _ConstruirEstadoVazio(filtrado: _temFiltroAtivo, isDark: isDark)
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
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : corAzulMarinho,
                                            ),
                                          ),
                                        ),
                                        ...analisesDoMes.map(
                                          (a) => _CartaoHistoricoDetalhado(
                                            analise: a,
                                            isDark: isDark,
                                            aoClicar: () async {
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => TelaDetalheAnalise(analiseId: a['id']),
                                                ),
                                              );
                                              _carregar();
                                            },
                                          ),
                                        ),
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
  final bool isDark;
  const _ConstruirEstadoErro({Key? key, required this.aoTentarNovamente, required this.isDark}) : super(key: key);

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
            Text(
              'Não foi possível carregar o histórico',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique sua conexão com a internet e se o servidor está acessível.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
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
  final bool isDark;
  const _ConstruirEstadoVazio({Key? key, this.filtrado = false, required this.isDark}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorTextoSecundario = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              filtrado ? Icons.filter_alt_off_outlined : Icons.history_toggle_off_outlined,
              size: 64,
              color: colorTextoSecundario.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              filtrado ? 'Nenhum resultado para esse filtro' : 'Histórico Vazio',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              filtrado
                  ? 'Tente ajustar o resultado ou o período selecionado.'
                  : 'As análises concluídas aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorTextoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoHistoricoDetalhado extends StatelessWidget {
  final dynamic analise;
  final bool isDark;
  final VoidCallback aoClicar;

  const _CartaoHistoricoDetalhado({
    Key? key,
    required this.analise,
    required this.isDark,
    required this.aoClicar,
  }) : super(key: key);

  Map<String, dynamic> get _statusConfig {
    final resultado = (analise['resultado']?.toString() ?? 'Desconhecido').toLowerCase();

    if (resultado.contains('possível') || resultado.contains('suspeita') || resultado.contains('mastite')) {
      return {
        'corBorda': Colors.redAccent,
        'corFundoTag': isDark ? Colors.red.shade900.withOpacity(0.4) : Colors.red.shade50,
        'corTextoTag': isDark ? Colors.red.shade200 : Colors.red.shade700,
        'icone': Icons.error_outline,
        'label': 'Suspeita Detectada'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corBorda': Colors.amber.shade700,
        'corFundoTag': isDark ? Colors.amber.shade900.withOpacity(0.4) : Colors.amber.shade50,
        'corTextoTag': isDark ? Colors.amber.shade200 : Colors.amber.shade900,
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção Necessária'
      };
    } else {
      return {
        'corBorda': const Color(0xFF10B981),
        'corFundoTag': const Color(0xFF10B981).withOpacity(isDark ? 0.2 : 0.12),
        'corTextoTag': isDark ? const Color(0xFF34D399) : const Color(0xFF10B981),
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
    final colorCard = isDark ? const Color(0xFF1E293B) : Colors.white;
    final colorBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final colorTextoPrimario = isDark ? Colors.white : const Color(0xFF0F172A);
    final colorTextoSecundario = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(color: config['corBorda'], width: 4),
          top: BorderSide(color: colorBorder, width: 1),
          right: BorderSide(color: colorBorder, width: 1),
          bottom: BorderSide(color: colorBorder, width: 1),
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
                // Miniatura da foto
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorBorder, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.science, color: colorTextoSecundario, size: 28),
                          )
                        : Icon(Icons.science, color: colorTextoSecundario, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                // Informações principais
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                        style: TextStyle(
                          fontSize: 13,
                          color: colorTextoPrimario,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: colorTextoSecundario),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _formatarDataHora(analise['criado_em']),
                              style: TextStyle(fontSize: 12, color: colorTextoSecundario),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorTextoSecundario, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}