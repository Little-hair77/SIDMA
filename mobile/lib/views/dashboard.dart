import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tela_captura.dart';
import 'tela_historico.dart';
import 'tela_login.dart';

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

  // DEFINIÇÃO DA PALETA DE CORES VÍVIDAS (IDENTIDADE SIDMA)
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corFundo = Color(0xFFF8FAFC); // Slate 50 - Fundo super limpo
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _carregando = true);

    final usuario = await _apiService.obterUsuarioSalvo();
    final historico = await _apiService.buscarHistorico();

    setState(() {
      _nomeUsuario = usuario['nome']?.isNotEmpty == true ? usuario['nome']! : (usuario['email'] ?? '');
      _analises = historico ?? [];
      _carregando = false;
    });
  }

  Future<void> _sair() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (route) => false,
    );
  }

  int get _totalAnalises => _analises.length;

  int get _totalSuspeitas =>
      _analises.where((a) => (a['resultado'] as String).contains('Possível')).length;

  String get _percentualSuspeitas {
    if (_totalAnalises == 0) return '0%';
    final percentual = (_totalSuspeitas / _totalAnalises) * 100;
    return '${percentual.toStringAsFixed(0)}%';
  }

  String get _dataUltimaAnalise {
    if (_analises.isEmpty) return '—';
    final data = DateTime.tryParse(_analises.first['criado_em'] ?? '');
    if (data == null) return '—';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // Evita que o Flutter escureça a barra ao rolar
        elevation: 1, // Sombra muito sutil
        shadowColor: Colors.black12,
        title: const Text(
          'SIDMA',
          style: TextStyle(
            color: corAzulPrincipal,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
          : RefreshIndicator(
              color: corAzulPrincipal,
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  // --- CABEÇALHO DE BOAS VINDAS ---
                  Text(
                    'Olá, $_nomeUsuario 👋',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: corTextoPrimario,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Visão geral do monitoramento sanitário',
                    style: TextStyle(color: Colors.black54, fontSize: 15),
                  ),
                  const SizedBox(height: 28),

                  // --- CARTÕES DE MÉTRICAS ---
                  Row(
                    children: [
                      _CartaoResumo(
                        titulo: 'Análises',
                        valor: '$_totalAnalises',
                        icone: Icons.science_outlined,
                        corIcone: corAzulPrincipal,
                        corFundoIcone: corAzulPrincipal.withOpacity(0.1),
                      ),
                      const SizedBox(width: 12),
                      _CartaoResumo(
                        titulo: 'Suspeitas',
                        valor: _percentualSuspeitas,
                        icone: Icons.warning_amber_rounded,
                        corIcone: Colors.orange.shade700,
                        corFundoIcone: Colors.orange.withOpacity(0.1),
                      ),
                      const SizedBox(width: 12),
                      _CartaoResumo(
                        titulo: 'Última',
                        valor: _dataUltimaAnalise,
                        icone: Icons.calendar_month_outlined,
                        corIcone: corVerdePrincipal,
                        corFundoIcone: corVerdePrincipal.withOpacity(0.1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- BOTÃO DE AÇÃO PRINCIPAL ---
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const TelaCaptura()))
                          .then((_) => _carregarDados());
                    },
                    icon: const Icon(Icons.camera_alt_outlined, size: 24),
                    label: const Text(
                      'NOVA ANÁLISE COM IA',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corVerdePrincipal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      elevation: 3,
                      shadowColor: corVerdePrincipal.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // --- CABEÇALHO DA LISTA ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Histórico Recente',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: corTextoPrimario,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TelaHistorico()),
                          );
                        },
                        style: TextButton.styleFrom(foregroundColor: corAzulPrincipal),
                        child: const Text('Ver tudo', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // --- LISTA DE ANÁLISES ---
                  if (_analises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'Nenhuma amostra processada ainda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black54, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  else
                    ..._analises.take(5).map((a) => _CartaoAnalise(analise: a)),
                ],
              ),
            ),
    );
  }
}

// ============================================================================
// COMPONENTES (WIDGETS EXTRAÍDOS)
// ============================================================================

class _CartaoResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color corIcone;
  final Color corFundoIcone;

  const _CartaoResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.corIcone,
    required this.corFundoIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Ícone dentro de um círculo colorido suave
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: corFundoIcone,
                shape: BoxShape.circle,
              ),
              child: Icon(icone, color: corIcone, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              valor,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _TelaDashboardState.corTextoPrimario,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
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

  // Lógica para definir Cores e Textos da Etiqueta (Badge)
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
        children: [
          // Thumbnail da Imagem
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                analise['imagem_url'] ?? '',
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 64,
                  height: 64,
                  color: Colors.grey.shade50,
                  child: Icon(Icons.science, color: Colors.grey.shade300, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Textos e Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Etiqueta Visual (Badge) do Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: config['corFundo'],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config['icone'], size: 14, color: config['corTexto']),
                      const SizedBox(width: 4),
                      Text(
                        config['label'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: config['corTexto'],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confiança da IA: ${analise['confianca'] ?? 'N/A'}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  analise['criado_em'] != null 
                      ? 'Processado em ${DateTime.tryParse(analise['criado_em'])?.day.toString().padLeft(2, '0')}/${DateTime.tryParse(analise['criado_em'])?.month.toString().padLeft(2, '0')}'
                      : 'Data desconhecida',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          
          // Seta indicativa de clique (se você for implementar navegação para detalhes depois)
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}