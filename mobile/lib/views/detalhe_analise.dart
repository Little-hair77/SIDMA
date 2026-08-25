import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scanner_qr.dart';

class TelaDetalheAnalise extends StatefulWidget {
  final int analiseId;
  const TelaDetalheAnalise({Key? key, required this.analiseId}) : super(key: key);

  @override
  State<TelaDetalheAnalise> createState() => _TelaDetalheAnaliseState();
}

class _TelaDetalheAnaliseState extends State<TelaDetalheAnalise> {
  final ApiService _apiService = ApiService();
  final _observacoesController = TextEditingController();

  Map<String, dynamic>? _analise;
  List<dynamic> _animais = [];
  bool _carregando = true;
  bool _salvando = false;
  bool _alterado = false;
  
  // Paleta de Cores
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final analise = await _apiService.buscarDetalheAnalise(widget.analiseId);
    final animais = await _apiService.listarAnimais();
    if (!mounted) return;
    setState(() {
      _analise = analise;
      _animais = animais ?? [];
      _observacoesController.text = analise?['observacoes'] ?? '';
      _carregando = false;
    });
  }

  // - Lógica de Cores e Ícones do Laudo
  Map<String, dynamic> get _statusConfig {
    final resultado = _analise?['resultado'] as String? ?? '';
    final resultadoLower = resultado.toLowerCase();
    
    if (resultadoLower.contains('possível') || resultadoLower.contains('suspeita') || resultadoLower.contains('mastite')) {
      return {
        'corFundo': Colors.redAccent, 
        'corTexto': Colors.white,
        'icone': Icons.warning_amber_rounded,
        'titulo': 'ALERTA: Suspeita Detectada',
        'detalhe': resultado,
      };
    } else if (resultadoLower.contains('adicional') || resultadoLower.contains('atenção')) {
      return {
        'corFundo': Colors.orange.shade600, 
        'corTexto': Colors.white,
        'icone': Icons.info_outline,
        'titulo': 'ATENÇÃO: Requer Cuidados',
        'detalhe': resultado,
      };
    } else {
      return {
        'corFundo': corVerdeEscuro, 
        'corTexto': Colors.white,
        'icone': Icons.check_circle_outline,
        'titulo': 'LAUDO NORMAL: Saudável',
        'detalhe': resultado,
      };
    }
  }

  String _formatarData(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _salvarObservacoes() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, observacoes: _observacoesController.text.trim());
    setState(() {
      _salvando = false;
      _alterado = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Observações salvas.' : 'Erro ao salvar. Tente novamente.'),
        backgroundColor: ok ? corVerdeEscuro : Colors.redAccent,
      ),
    );
  }

  Future<void> _vincularAnimal(dynamic animal) async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, animalId: animal['id']);
    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _desvincularAnimal() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, desvincularAnimal: true);
    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _escanearParaVincular() async {
    final valorLido = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const TelaScannerQr()),
    );
    if (valorLido == null) return;

    final partes = valorLido.split('|');
    dynamic animalEncontrado;
    if (partes.length == 3 && partes[0] == 'SIDMA-ANIMAL') {
      final idLido = int.tryParse(partes[1]);
      animalEncontrado = _animais.firstWhere((a) => a['id'] == idLido, orElse: () => null);
    } else {
      animalEncontrado = _animais.firstWhere((a) => a['brinco'] == valorLido, orElse: () => null);
    }

    if (animalEncontrado != null) {
      _vincularAnimal(animalEncontrado);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum animal cadastrado corresponde a esse código.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _mostrarSeletorDeAnimal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Vincular Animal ao Laudo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: corVerdeEscuro),
              title: const Text('Escanear QR Code', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                _escanearParaVincular();
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _animais.map((a) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: corVerdeEscuro.withOpacity(0.1),
                          child: const Icon(Icons.pets, color: corVerdeEscuro, size: 20),
                        ),
                        title: Text(
                          a['nome']?.isNotEmpty == true ? '${a['nome']}' : 'Sem Nome',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('Brinco: ${a['brinco']}'),
                        onTap: () {
                          Navigator.of(context).pop();
                          _vincularAnimal(a);
                        },
                      )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corVerdeEscuro))
          : _analise == null
              ? const Center(child: Text('Não foi possível carregar essa análise.'))
              : CustomScrollView(
                  slivers: [
                    // 1 - CABEÇALHO (Com a Foto)
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          // - Fundo Verde Superior 
                          Container(
                            height: 240,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: corVerdeEscuro,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                            child: SafeArea(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Text(
                                        'Laudo de Análise',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 48), 
                                ],
                              ),
                            ),
                          ),

                          // - Foto da Análise Sobreposta
                          Padding(
                            padding: const EdgeInsets.only(top: 110, left: 20, right: 20, bottom: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _analise!['imagem_url'],
                                  width: double.infinity,
                                  height: 260,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 260,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 2 - CORPO DO LAUDO
                    SliverToBoxAdapter(
                      child: Stack(
                        children: [
                          // Marca D'água
                          Positioned.fill(
                            child: Center(
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
                          ),
                          
                          // Conteúdo
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // - BLOCO DO RESULTADO 
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: _statusConfig['corFundo'], 
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _statusConfig['corFundo'].withOpacity(0.35), 
                                        blurRadius: 15, 
                                        offset: const Offset(0, 6)
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(_statusConfig['icone'], color: _statusConfig['corTexto'], size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _statusConfig['titulo'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: _statusConfig['corTexto'], 
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        _statusConfig['detalhe'],
                                        style: TextStyle(fontSize: 15, color: _statusConfig['corTexto'].withOpacity(0.9), fontWeight: FontWeight.w500),
                                      ),
                                      Divider(height: 32, thickness: 1, color: _statusConfig['corTexto'].withOpacity(0.3)), // Divisor sutil
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Confiança IA', style: TextStyle(fontSize: 12, color: _statusConfig['corTexto'].withOpacity(0.8))),
                                              Text(
                                                '${_analise!['confianca']}',
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _statusConfig['corTexto']),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text('Data do Exame', style: TextStyle(fontSize: 12, color: _statusConfig['corTexto'].withOpacity(0.8))),
                                              Text(
                                                _formatarData(_analise!['criado_em']),
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _statusConfig['corTexto']),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),
                                
                                // - BLOCO DO ANIMAL VINCULADO
                                const Text('Vínculo Zootécnico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTextoPrimario)),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade200),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: corVerdeEscuro.withOpacity(0.1),
                                        radius: 24,
                                        child: const Icon(Icons.pets, color: corVerdeEscuro),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _analise!['animal'] != null
                                                  ? '${_analise!['animal']['nome']?.isNotEmpty == true ? _analise!['animal']['nome'] : 'Sem Nome'}'
                                                  : 'Nenhum animal vinculado',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: _analise!['animal'] != null ? corTextoPrimario : Colors.grey,
                                              ),
                                            ),
                                            if (_analise!['animal'] != null)
                                              Text(
                                                'Brinco: ${_analise!['animal']['brinco']}',
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (_analise!['animal'] != null)
                                        IconButton(
                                          icon: const Icon(Icons.link_off, size: 22, color: Colors.redAccent),
                                          tooltip: 'Desvincular do animal',
                                          onPressed: _salvando ? null : _desvincularAnimal,
                                        ),
                                      TextButton(
                                        onPressed: _salvando ? null : _mostrarSeletorDeAnimal,
                                        child: Text(
                                          _analise!['animal'] != null ? 'Trocar' : 'Vincular',
                                          style: const TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // - BLOCO DE OBSERVAÇÕES CLÍNICAS
                                const Text('Observações Clínicas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: corTextoPrimario)),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _observacoesController,
                                  maxLines: 4,
                                  onChanged: (_) => setState(() => _alterado = true),
                                  style: const TextStyle(color: corTextoPrimario),
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Realizado teste da caneca de fundo preto. Prescrição de antibiótico...',
                                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(color: Colors.grey.shade200),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: corVerdeEscuro, width: 1.5),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Botão de Salvar apenas se houver alterações
                                if (_alterado)
                                  ElevatedButton.icon(
                                    onPressed: _salvando ? null : _salvarObservacoes,
                                    label: Text(
                                      _salvando ? 'Salvando...' : 'Salvar Observações',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: corVerdeEscuro,
                                      minimumSize: const Size(double.infinity, 56),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 2,
                                    ),
                                  ),

                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}