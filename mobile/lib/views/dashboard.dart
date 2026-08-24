import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'captura.dart';
import 'historico.dart';
import 'login.dart';
import 'detalhe_analise.dart';
// import 'animais.dart'; 

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

  // PALETA DE CORES 
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86); 
  static const Color corVerdeClaro = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
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

    if (!mounted) return;

    setState(() {
      _nomeUsuario = usuario['nome']?.isNotEmpty == true ? usuario['nome']! : (usuario['email'] ?? 'Produtor');
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
          ),
          child: const Center(
            child: Text(
              'Nenhuma amostra processada ainda.',
              style: TextStyle(color: Colors.black54),
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
          ? const Center(child: CircularProgressIndicator(color: corVerdeEscuro))
          : RefreshIndicator(
              color: corVerdeEscuro,
              onRefresh: _carregarDados,
              child: CustomScrollView(
                slivers: [

                  // 1 - HEADER & GRID SOBREPOSTO (OVERLAP)
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        // --- O FUNDO VERDE FIXO ---
                        Container(
                          height: 230, // Altura que garante a margem para o overlap
                          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: corVerdeEscuro,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(32),
                              bottomRight: Radius.circular(32),
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
                                      'Gestão do Rebanho & SIDMA',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.logout, color: Colors.white),
                                onPressed: _sair,
                                tooltip: 'Sair',
                              ),
                            ],
                          ),
                        ),

                        // --- OS CARDS ---
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 140, 
                              left: 20, 
                              right: 20
                          ),
                          child: GridView.count(
                            shrinkWrap: true, // Importante para não dar erro de tamanho no Stack
                            physics: const NeverScrollableScrollPhysics(), // Desativa rolagem interna
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1,
                            padding: EdgeInsets.zero,
                            children: [
                              _ModuloCard(
                                titulo: 'Meu Rebanho',
                                icone: Icons.pets,
                                corIcone: corVerdeClaro,
                                onTap: () {
                                  // Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaAnimais()));
                                },
                              ),
                              _ModuloCard(
                                titulo: 'Diagnóstico IA',
                                icone: Icons.document_scanner_outlined,
                                corIcone: corAzulPrincipal,
                                notificacao: 'Novo',
                                onTap: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(builder: (_) => const TelaCaptura()))
                                      .then((_) => _carregarDados());
                                },
                              ),
                              _ModuloCard(
                                titulo: 'Tratamento Sanitário',
                                icone: Icons.medical_services_outlined,
                                corIcone: Colors.redAccent,
                                onTap: () {
                                  // TODO: Navegar para tela de Tratamentos
                                },
                              ),
                              _ModuloCard(
                                titulo: 'Histórico & Laudos',
                                icone: Icons.history_edu_outlined,
                                corIcone: Colors.orange,
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

                  // 2 - AÇÕES RÁPIDAS (ESTILO LISTA LARGA)
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 24, left: 20, right: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _AcaoRapidaBotao(
                          titulo: 'Sincronizar Dados Offline',
                          icone: Icons.cloud_sync_outlined,
                          cor: Colors.teal,
                          onTap: () {},
                        ),
                        const SizedBox(height: 12),
                        _AcaoRapidaBotao(
                          titulo: 'Compartilhar Relatório',
                          icone: Icons.share_outlined,
                          cor: corAzulPrincipal,
                          destaque: true,
                          onTap: () {},
                        ),
                      ]),
                    ),
                  ),

                  // 3 - HISTÓRICO RECENTE
                  SliverPadding(
                    padding: const EdgeInsets.only(top: 32, left: 20, right: 20, bottom: 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const Text(
                          'Análises Recentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: corTextoPrimario,
                          ),
                        ),
                        const SizedBox(height: 16),
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
// WIDGETS AUXILIARES
// ==========================================

class _ModuloCard extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final Color corIcone;
  final String? notificacao;
  final VoidCallback onTap;

  const _ModuloCard({
    required this.titulo,
    required this.icone,
    required this.corIcone,
    this.notificacao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
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
                Icon(icone, color: corIcone, size: 32),
                if (notificacao != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notificacao!,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                    ),
                  ),
              ],
            ),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _TelaDashboardState.corTextoPrimario,
                height: 1.2,
              ),
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
  final Color cor;
  final bool destaque;
  final VoidCallback onTap;

  const _AcaoRapidaBotao({
    required this.titulo,
    required this.icone,
    required this.cor,
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
          color: destaque ? cor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: destaque ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: destaque
              ? [BoxShadow(color: cor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: destaque ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icone, color: destaque ? Colors.white : cor, size: 20),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
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
      return {'corTexto': Colors.red.shade700, 'corFundo': Colors.red.shade50, 'icone': Icons.error_outline, 'label': 'Suspeita'};
    } else if (resultado.contains('adicional') || resultado.contains('atenção')) {
      return {'corTexto': Colors.orange.shade800, 'corFundo': Colors.orange.shade50, 'icone': Icons.warning_amber_rounded, 'label': 'Atenção'};
    } else {
      return {'corTexto': Colors.green.shade700, 'corFundo': Colors.green.shade50, 'icone': Icons.check_circle_outline, 'label': 'Saudável'};
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                analise['imagem_url'] ?? '',
                width: 64, height: 64, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey.shade50, child: Icon(Icons.science, color: Colors.grey.shade300, size: 28)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: config['corFundo'], borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config['icone'], size: 14, color: config['corTexto']),
                      const SizedBox(width: 4),
                      Text(config['label'], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: config['corTexto'])),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text('Confiança: ${analise['confianca'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }
}