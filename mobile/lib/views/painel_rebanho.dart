import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detalhe_animal.dart';

class TelaPainelRebanho extends StatefulWidget {
  const TelaPainelRebanho({Key? key}) : super(key: key);

  @override
  State<TelaPainelRebanho> createState() => _TelaPainelRebanhoState();
}

class _TelaPainelRebanhoState extends State<TelaPainelRebanho> {
  final ApiService _apiService = ApiService();

  List<dynamic> _animais = [];
  bool _carregando = true;

  // Paleta de Cores 
  static const Color corAzulMarinho = Color(0xFF1E293B);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF0F172A);
  static const Color corTextoSecundario = Color(0xFF64748B);
  static const Color corVerdePrimaria = Color(0xFF10B981);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await _apiService.listarAnimais();
    if (!mounted) return;
    setState(() {
      _animais = lista ?? [];
      _carregando = false;
    });
  }

  List<dynamic> get _emCarencia => _animais.where((a) => a['em_carencia'] == true).toList();
  List<dynamic> get _cioPrevisto => _animais.where((a) => a['cio_proximo'] == true).toList();
  List<dynamic> get _ccsElevado => _animais.where((a) => a['ultimo_ccs_risco'] == 'ALTO').toList();
  List<dynamic> get _reincidencia => _animais.where((a) => a['alerta_reincidencia'] == true).toList();

  Future<void> _abrirFicha(dynamic animal) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)),
    );
    _carregar();
  }

  String _formatarData(String? dataIso) {
    final data = DateTime.tryParse(dataIso ?? '');
    if (data == null) return 'N/I';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalAtencao = _emCarencia.length + _cioPrevisto.length + _ccsElevado.length + _reincidencia.length;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corAzulMarinho,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Painel do Rebanho', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
          : RefreshIndicator(
              color: corVerdePrimaria,
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Resumo de manejo com base em ${_animais.length} animal(is) cadastrado(s).',
                    style: const TextStyle(fontSize: 12, color: corTextoSecundario),
                  ),
                  const SizedBox(height: 16),

                  // RESUMO EM NÚMEROS
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.7,
                    children: [
                      _StatCard(titulo: 'Em Carência', valor: _emCarencia.length, icone: Icons.medical_information_outlined, cor: const Color(0xFFEF4444)),
                      _StatCard(titulo: 'Cio Previsto', valor: _cioPrevisto.length, icone: Icons.favorite_outline, cor: const Color(0xFFDB2777)),
                      _StatCard(titulo: 'CCS Elevado', valor: _ccsElevado.length, icone: Icons.biotech_outlined, cor: const Color(0xFF2563EB)),
                      _StatCard(titulo: 'Reincidência', valor: _reincidencia.length, icone: Icons.repeat_rounded, cor: const Color(0xFFF97316)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (totalAtencao == 0)
                    _buildEstadoVazio()
                  else ...[
                    _buildSecao(
                      titulo: 'Em Carência',
                      subtitulo: 'O leite desses animais não deve ser misturado ao tanque.',
                      icone: Icons.medical_information_outlined,
                      cor: const Color(0xFFEF4444),
                      animais: _emCarencia,
                      detalheBuilder: (a) => 'Carência até ${_formatarData(a['carencia_ate'])}',
                    ),
                    _buildSecao(
                      titulo: 'Cio Previsto',
                      subtitulo: 'Atenção reprodutiva — previsão baseada no último cio registrado.',
                      icone: Icons.favorite_outline,
                      cor: const Color(0xFFDB2777),
                      animais: _cioPrevisto,
                      detalheBuilder: (a) => 'Previsão: ${_formatarData(a['previsao_proximo_cio'])}',
                    ),
                    _buildSecao(
                      titulo: 'CCS Elevado',
                      subtitulo: 'Risco de mastite subclínica pela Contagem de Células Somáticas.',
                      icone: Icons.biotech_outlined,
                      cor: const Color(0xFF2563EB),
                      animais: _ccsElevado,
                      detalheBuilder: (a) => 'Último CCS: ${a['ultimo_ccs_valor'] ?? 'N/I'} céls/mL',
                    ),
                    _buildSecao(
                      titulo: 'Reincidência de Mastite',
                      subtitulo: '2 ou mais resultados suspeitos entre as últimas 3 análises.',
                      icone: Icons.repeat_rounded,
                      cor: const Color(0xFFF97316),
                      animais: _reincidencia,
                      detalheBuilder: (a) => '${a['total_analises'] ?? 0} análise(s) registrada(s)',
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 56, color: corVerdePrimaria.withOpacity(0.6)),
          const SizedBox(height: 12),
          const Text(
            'Nenhum alerta de manejo no momento',
            style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Assim que algum animal entrar em carência, cio previsto, CCS elevado ou reincidência de mastite, ele aparece aqui.',
            style: TextStyle(color: corTextoSecundario, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required List<dynamic> animais,
    required String Function(dynamic) detalheBuilder,
  }) {
    if (animais.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cor.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icone, color: cor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$titulo (${animais.length})', style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario, fontSize: 14)),
                      Text(subtitulo, style: const TextStyle(fontSize: 11, color: corTextoSecundario)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...animais.map((a) => _buildLinhaAnimal(a, cor, detalheBuilder)).toList(),
        ],
      ),
    );
  }

  Widget _buildLinhaAnimal(dynamic animal, Color cor, String Function(dynamic) detalheBuilder) {
    return InkWell(
      onTap: () => _abrirFicha(animal),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: corFundo,
              backgroundImage: animal['foto'] != null ? NetworkImage(animal['foto']) : null,
              child: animal['foto'] == null ? const Icon(Icons.pets, size: 16, color: corTextoSecundario) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal['nome']?.toString().isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: corTextoPrimario, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(detalheBuilder(animal), style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final int valor;
  final IconData icone;
  final Color cor;

  const _StatCard({required this.titulo, required this.valor, required this.icone, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icone, color: cor, size: 20),
              Text(
                '$valor',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: valor > 0 ? cor : const Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}