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
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('SIDMA'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Olá, $_nomeUsuario',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resumo do monitoramento do rebanho',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // Cards de resumo
                  Row(
                    children: [
                      _CartaoResumo(
                        titulo: 'Análises',
                        valor: '$_totalAnalises',
                        icone: Icons.science_outlined,
                        cor: Colors.teal,
                      ),
                      const SizedBox(width: 12),
                      _CartaoResumo(
                        titulo: 'Suspeitas',
                        valor: _percentualSuspeitas,
                        icone: Icons.warning_amber_rounded,
                        cor: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _CartaoResumo(
                        titulo: 'Última',
                        valor: _dataUltimaAnalise,
                        icone: Icons.calendar_today_outlined,
                        cor: Colors.indigo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Botão de destaque
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TelaCaptura()),
                      ).then((_) => _carregarDados());
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Nova Análise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Cabeçalho da lista recente
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Análises recentes',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TelaHistorico()),
                          );
                        },
                        child: const Text('Ver tudo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_analises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'Nenhuma análise realizada ainda.\nToque em "Nova Análise" para começar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
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

class _CartaoResumo extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color cor;

  const _CartaoResumo({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Icon(icone, color: cor, size: 22),
            const SizedBox(height: 8),
            Text(valor, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(titulo, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _CartaoAnalise extends StatelessWidget {
  final dynamic analise;

  const _CartaoAnalise({required this.analise});

  Color get _corResultado {
    final resultado = analise['resultado'] as String;
    if (resultado.contains('Possível')) return Colors.red;
    if (resultado.contains('adicional')) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
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
              analise['imagem_url'],
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
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
                  analise['resultado'],
                  style: TextStyle(fontWeight: FontWeight.bold, color: _corResultado, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Confiança: ${analise['confianca']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}