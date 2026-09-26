import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart';
import 'animais.dart';
import 'captura.dart';
import 'historico.dart';
import 'login.dart';
import 'detalhe_analise.dart';
import 'alerta_bell_button.dart';
import 'painel_rebanho.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({Key? key}) : super(key: key);

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  final ApiService _apiService = ApiService();

  bool _carregando = true;
  String _nomeUsuario = '';
  List<dynamic> _analises = [];

  // Métricas calculadas a partir dos dados reais retornados pela API
  int _totalAnimais = 0;
  int _emTratamento = 0;
  int _totalSituacoesEmAberto = 0;

  // Paleta de Cores
  static const Color corVerdePrimaria = Color(0xFF10B981); 
  static const Color corVerdeEscuro = Color(0xFF059669);   
  static const Color corVerdeSuave = Color(0xFFECFDF5);    
  static const Color corAzulMarinho = Color(0xFF1E293B);   
  static const Color corFundo = Color(0xFFF8FAFC);         
  static const Color corTextoPrimario = Color(0xFF0F172A); 
  static const Color corTextoSecundario = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final usuario = await _apiService.obterUsuarioSalvo();
    final historico = await _apiService.buscarHistorico();
    final animais = await _apiService.listarAnimais();

    if (!mounted) return;

    final listaAnimais = animais ?? [];
    final totalEmCarencia = listaAnimais
        .where((a) => a['em_carencia'] == true)
        .length;

    final totalSituacoes = totalEmCarencia +
        listaAnimais.where((a) => a['cio_proximo'] == true).length +
        listaAnimais.where((a) => a['ultimo_ccs_risco'] == 'ALTO').length +
        listaAnimais.where((a) => a['alerta_reincidencia'] == true).length;

    setState(() {
      _nomeUsuario = usuario['nome']?.isNotEmpty == true ? usuario['nome']! : (usuario['email'] ?? 'Produtor');
      _analises = historico ?? [];
      _totalAnimais = listaAnimais.length;
      _emTratamento = totalEmCarencia;
      _totalSituacoesEmAberto = totalSituacoes;
      _carregando = false;
    });
  }

  Future<void> _compartilharRelatorio() async {
    final documento = pw.Document();
    final agora = DateTime.now();
    final dataGerado =
        '${agora.day.toString().padLeft(2, '0')}/${agora.month.toString().padLeft(2, '0')}/${agora.year}';

    documento.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'SIDMA - Relatório de Diagnósticos',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Gerado em: $dataGerado', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 16),
            pw.Text('Total de animais no rebanho: $_totalAnimais'),
            pw.Text('Animais em tratamento/carência: $_emTratamento'),
            pw.Text('Total de análises registradas: ${_analises.length}'),
            pw.Text('Análises com suspeita de mastite: $_suspeitasDiagnostico'),
            pw.SizedBox(height: 16),
            pw.Text('Últimas análises:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            ..._analises.take(10).map((a) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(
                    '${a['criado_em'] ?? 'Data N/I'} — ${a['resultado'] ?? 'N/I'} (confiança: ${a['confianca'] ?? 'N/A'})',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                )),
            pw.SizedBox(height: 20),
            pw.Text(
              'Documento gerado pelo SIDMA — Sistema Inteligente de Auxílio ao Diagnóstico de Mastite.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ),
    );

    await Printing.sharePdf(bytes: await documento.save(), filename: 'relatorio_sidma.pdf');
  }

  void _sincronizarDadosOffline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sincronização offline ainda não está disponível nesta versão.')),
    );
  }

  Future<void> _sair() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (route) => false,
    );
  }

  int get _suspeitasDiagnostico {
    return _analises.where((a) => _ehSuspeita(a)).length;
  }

  static bool _ehSuspeita(dynamic analise) {
    final res = (analise['resultado'] ?? '').toString().toLowerCase();
    return res.contains('possível') || res.contains('suspeita') || res.contains('mastite');
  }

  /// Agrupa as análises dos últimos 7 dias (incluindo hoje) por data,
  /// contando o total de análises e quantas foram sinalizadas como suspeitas.
  /// Usado para alimentar o gráfico de tendência do Dashboard (RF26).
  List<Map<String, dynamic>> _dadosTendencia() {
    final hoje = DateTime.now();
    final diaBase = DateTime(hoje.year, hoje.month, hoje.day);
    final dias = List.generate(7, (i) => diaBase.subtract(Duration(days: 6 - i)));

    return dias.map((dia) {
      final analisesDoDia = _analises.where((a) {
        final dt = DateTime.tryParse((a['criado_em'] ?? '').toString())?.toLocal();
        if (dt == null) return false;
        return dt.year == dia.year && dt.month == dia.month && dt.day == dia.day;
      }).toList();

      return {
        'data': dia,
        'total': analisesDoDia.length,
        'suspeitas': analisesDoDia.where((a) => _ehSuspeita(a)).length,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgetsHistorico = [];
    
    if (_analises.isEmpty) {
      widgetsHistorico.add(
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Center(
            child: Text(
              'Nenhuma amostra processada ainda.',
              style: TextStyle(color: corTextoSecundario),
            ),
          ),
        ),
      );
    } else {
      widgetsHistorico.addAll(
        _analises.take(4).map((a) => GestureDetector(
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TelaDetalheAnalise(analiseId: a['id'])),
            );
            _carregarDados();
          },
          child: _CartaoAnalise(analise: a),
        )).toList(),
      );
    }

    return Scaffold(
      backgroundColor: corFundo,
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
          : RefreshIndicator(
              color: corVerdePrimaria,
              onRefresh: _carregarDados,
              child: CustomScrollView(
                slivers: [

                  // 1 - HEADER MODERNO EM AZUL MARINHO
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Container(
                          height: 210,
                          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: corAzulMarinho,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(28),
                              bottomRight: Radius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Olá, $_nomeUsuario',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Gestão de Rebanho & Diagnóstico',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const BotaoSinoAlertas(corIcone: Colors.white),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                onPressed: _sair,
                                tooltip: 'Sair',
                              ),
                            ],
                          ),
                        ),

                        // - MÓDULOS COM DADOS E MÉTRICAS 
                        Padding(
                          padding: const EdgeInsets.only(top: 125, left: 20, right: 20),
                          child: GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                            padding: EdgeInsets.zero,
                            children: [
                              _ModuloCardData(
                                titulo: 'Meu Rebanho',
                                valor: '$_totalAnimais',
                                legenda: 'Cabeças ativas',
                                icone: Icons.agriculture_outlined,
                                corDestaque: corAzulMarinho,
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => const TelaAnimais()))
                                      .then((_) => _carregarDados());
                                },
                              ),
                              _ModuloCardData(
                                titulo: 'Diagnósticos IA',
                                valor: '${_analises.length}',
                                legenda: '$_suspeitasDiagnostico em alerta',
                                icone: Icons.document_scanner_outlined,
                                corDestaque: corVerdePrimaria,
                                destaqueAlerta: _suspeitasDiagnostico > 0,
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => const TelaCaptura()))
                                      .then((_) => _carregarDados());
                                },
                              ),
                              _ModuloCardData(
                                titulo: 'Painel do Rebanho',
                                valor: '$_totalSituacoesEmAberto',
                                legenda: _totalSituacoesEmAberto > 0 ? 'Situações em aberto' : 'Tudo em ordem',
                                icone: Icons.health_and_safety_outlined,
                                corDestaque: const Color(0xFFF59E0B),
                                destaqueAlerta: _totalSituacoesEmAberto > 0,
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => const TelaPainelRebanho()))
                                      .then((_) => _carregarDados());
                                },
                              ),
                              _ModuloCardData(
                                titulo: 'Laudos',
                                valor: '${_analises.length}',
                                legenda: 'Histórico total',
                                icone: Icons.history_edu_outlined,
                                corDestaque: const Color(0xFF6366F1), // Índigo
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const TelaHistorico()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2 - GRÁFICO DE TENDÊNCIA (RF26)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                    sliver: SliverToBoxAdapter(
                      child: _GraficoTendencia(dados: _dadosTendencia()),
                    ),
                  ),

                  // 3 - AÇÕES RÁPIDAS
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _AcaoRapidaBotao(
                          titulo: 'Sincronizar Dados Offline',
                          icone: Icons.cloud_sync_outlined,
                          destaque: false,
                          onTap: _sincronizarDadosOffline,
                        ),
                        const SizedBox(height: 10),
                        _AcaoRapidaBotao(
                          titulo: 'Compartilhar Relatório',
                          icone: Icons.share_outlined,
                          destaque: true,
                          onTap: _compartilharRelatorio,
                        ),
                      ]),
                    ),
                  ),

                  // 4 - HISTÓRICO RECENTE
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 28, left: 20, right: 20, bottom: 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Últimas Análises de Mastite',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: corTextoPrimario,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...widgetsHistorico,
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ==========================================
// CARD DE DADOS & MÉTRICAS
// ==========================================

class _ModuloCardData extends StatelessWidget {
  final String titulo;
  final String valor;
  final String legenda;
  final IconData icone;
  final Color corDestaque;
  final bool destaqueAlerta;
  final VoidCallback onTap;

  const _ModuloCardData({
    required this.titulo,
    required this.valor,
    required this.legenda,
    required this.icone,
    required this.corDestaque,
    this.destaqueAlerta = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destaqueAlerta ? const Color(0xFFFCA5A5) : const Color(0xFFF1F5F9),
            width: destaqueAlerta ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _TelaDashboardState.corTextoSecundario,
                  ),
                ),
                Icon(icone, color: corDestaque, size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: destaqueAlerta ? const Color(0xFFDC2626) : _TelaDashboardState.corTextoPrimario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  legenda,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: destaqueAlerta ? FontWeight.bold : FontWeight.normal,
                    color: destaqueAlerta ? const Color(0xFFDC2626) : _TelaDashboardState.corTextoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AcaoRapidaBotao extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final bool destaque;
  final VoidCallback onTap;

  const _AcaoRapidaBotao({
    required this.titulo,
    required this.icone,
    this.destaque = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: destaque ? _TelaDashboardState.corVerdePrimaria : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: destaque ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: destaque
              ? [
                  BoxShadow(
                    color: _TelaDashboardState.corVerdePrimaria.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: destaque ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(
              icone,
              color: destaque ? Colors.white : _TelaDashboardState.corTextoPrimario,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: destaque ? Colors.white : _TelaDashboardState.corTextoPrimario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartaoAnalise extends StatelessWidget {
  final dynamic analise;
  const _CartaoAnalise({required this.analise});

  Map<String, dynamic> get _statusConfig {
    final resultado = (analise['resultado'] as String).toLowerCase();
    if (resultado.contains('possível') || resultado.contains('suspeita') || resultado.contains('mastite')) {
      return {
        'corTexto': const Color(0xFFDC2626),
        'corFundo': const Color(0xFFFEF2F2),
        'icone': Icons.error_outline,
        'label': 'Suspeita'
      };
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {
        'corTexto': const Color(0xFFD97706),
        'corFundo': const Color(0xFFFFFBEB),
        'icone': Icons.warning_amber_rounded,
        'label': 'Atenção'
      };
    } else {
      return {
        'corTexto': const Color(0xFF059669),
        'corFundo': const Color(0xFFECFDF5),
        'icone': Icons.check_circle_outline,
        'label': 'Saudável'
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                analise['imagem_url'] ?? '',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFFF8FAFC),
                  child: const Icon(Icons.science_outlined, color: Color(0xFF94A3B8), size: 24),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: config['corFundo'],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config['icone'], size: 12, color: config['corTexto']),
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
                const SizedBox(height: 6),
                Text(
                  'Confiança: ${analise['confianca'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _TelaDashboardState.corTextoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
        ],
      ),
    );
  }
}

// ==========================================
// GRÁFICO DE TENDÊNCIA 
// ==========================================

class _GraficoTendencia extends StatelessWidget {
  final List<Map<String, dynamic>> dados;
  const _GraficoTendencia({required this.dados});

  @override
  Widget build(BuildContext context) {
    final maiorTotal = dados
        .map((d) => d['total'] as int)
        .fold<int>(0, (a, b) => a > b ? a : b);
    // maxY nunca fica em 0 (evita gráfico "achatado" quando não há dados ainda)
    final maxY = (maiorTotal < 4 ? 4 : maiorTotal + 1).toDouble();
    final intervaloEixoY = (maxY / 4).clamp(1.0, double.infinity);

    final spotsTotal = <FlSpot>[
      for (var i = 0; i < dados.length; i++)
        FlSpot(i.toDouble(), (dados[i]['total'] as int).toDouble()),
    ];
    final spotsSuspeitas = <FlSpot>[
      for (var i = 0; i < dados.length; i++)
        FlSpot(i.toDouble(), (dados[i]['suspeitas'] as int).toDouble()),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendência de Diagnósticos (7 dias)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _TelaDashboardState.corTextoPrimario,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              _LegendaItem(cor: _TelaDashboardState.corAzulMarinho, texto: 'Total de análises'),
              SizedBox(width: 16),
              _LegendaItem(cor: Color(0xFFDC2626), texto: 'Suspeitas'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: dados.every((d) => (d['total'] as int) == 0)
                ? const Center(
                    child: Text(
                      'Ainda não há análises suficientes\npara exibir a tendência.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: _TelaDashboardState.corTextoSecundario),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (dados.length - 1).toDouble(),
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: intervaloEixoY,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0xFFF1F5F9),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: intervaloEixoY,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: const TextStyle(fontSize: 10, color: _TelaDashboardState.corTextoSecundario),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= dados.length) return const SizedBox.shrink();
                              final dia = dados[i]['data'] as DateTime;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '${dia.day.toString().padLeft(2, '0')}/${dia.month.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 10, color: _TelaDashboardState.corTextoSecundario),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spotsTotal,
                          isCurved: true,
                          color: _TelaDashboardState.corAzulMarinho,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: _TelaDashboardState.corAzulMarinho.withOpacity(0.08),
                          ),
                        ),
                        LineChartBarData(
                          spots: spotsSuspeitas,
                          isCurved: true,
                          color: const Color(0xFFDC2626),
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String texto;
  const _LegendaItem({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          texto,
          style: const TextStyle(fontSize: 11, color: _TelaDashboardState.corTextoSecundario),
        ),
      ],
    );
  }
}