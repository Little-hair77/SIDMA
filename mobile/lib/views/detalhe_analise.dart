import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scanner_qr.dart';

class TelaDetalheAnalise extends StatefulWidget {
  final int analiseId;

  const TelaDetalheAnalise({super.key, required this.analiseId});

  @override
  State<TelaDetalheAnalise> createState() => _TelaDetalheAnaliseState();
}

class _TelaDetalheAnaliseState extends State<TelaDetalheAnalise> {
  final ApiService _apiService = ApiService();
  final TextEditingController _observacoesController = TextEditingController();

  Map<String, dynamic>? _analise;
  List<dynamic> _animais = [];
  bool _carregando = true;
  bool _salvando = false;
  bool _alterado = false;

  // Paleta de Cores 
  static const Color corVerdeEscuro = Color(0xFF1DB156);
  static const Color corAppBar = Color(0xFF1E2A38);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF0F172A);
  static const Color corTextoSecundario = Color(0xFF64748B);
  static const Color corBorda = Color(0xFFE2E8F0);

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
      _observacoesController.text = analise?['observacoes'] as String? ?? '';
      _carregando = false;
    });
  }

  // Estilos sutis de status 
  Map<String, dynamic> get _statusConfig {
    final resultado = _analise?['resultado'] as String? ?? '';
    final resultadoLower = resultado.toLowerCase();

    if (resultadoLower.contains('possível') ||
        resultadoLower.contains('suspeita') ||
        resultadoLower.contains('mastite')) {
      return {
        'corFundo': const Color(0xFFFEF2F2),
        'corBorda': const Color(0xFFFCA5A5),
        'corDestaque': const Color(0xFFDC2626),
        'icone': Icons.warning_amber_rounded,
        'titulo': 'ALERTA: Suspeita Detectada',
        'detalhe': resultado,
      };
    } else if (resultadoLower.contains('adicional') ||
        resultadoLower.contains('atenção')) {
      return {
        'corFundo': const Color(0xFFFFFBEB),
        'corBorda': const Color(0xFFFDE68A),
        'corDestaque': const Color(0xFFD97706),
        'icone': Icons.info_outline,
        'titulo': 'ATENÇÃO: Requer Cuidados',
        'detalhe': resultado,
      };
    } else {
      return {
        'corFundo': const Color(0xFFF0FDF4),
        'corBorda': const Color(0xFF86EFAC),
        'corDestaque': const Color(0xFF16A34A),
        'icone': Icons.check_circle_outline,
        'titulo': 'LAUDO NORMAL: Saudável',
        'detalhe': resultado,
      };
    }
  }

  String _formatarData(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return '';
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  Future<void> _salvarObservacoes() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(
      widget.analiseId,
      observacoes: _observacoesController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _salvando = false;
      _alterado = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Observações salvas com sucesso.' : 'Erro ao salvar. Tente novamente.',
        ),
        backgroundColor: ok ? corVerdeEscuro : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _vincularAnimal(dynamic animal) async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(
      widget.analiseId,
      animalId: animal['id'] as int?,
    );

    if (!mounted) return;

    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _desvincularAnimal() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(
      widget.analiseId,
      desvincularAnimal: true,
    );

    if (!mounted) return;

    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _escanearParaVincular() async {
    final valorLido = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const TelaScannerQr()),
    );

    if (valorLido == null || !mounted) return;

    final partes = valorLido.split('|');
    dynamic animalEncontrado;

    if (partes.length == 3 && partes[0] == 'SIDMA-ANIMAL') {
      final idLido = int.tryParse(partes[1]);
      animalEncontrado = _animais.firstWhere(
        (a) => a['id'] == idLido,
        orElse: () => null,
      );
    } else {
      animalEncontrado = _animais.firstWhere(
        (a) => a['brinco'] == valorLido,
        orElse: () => null,
      );
    }

    if (animalEncontrado != null) {
      _vincularAnimal(animalEncontrado);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum animal cadastrado corresponde a esse código.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _mostrarSeletorDeAnimal() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Vincular Animal ao Laudo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: corTextoPrimario,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: corVerdeEscuro),
              title: const Text(
                'Escanear QR Code',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onTap: () {
                Navigator.of(modalContext).pop();
                _escanearParaVincular();
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: _animais.map((a) {
                    final nomeAnimal = (a['nome'] as String?)?.isNotEmpty == true
                        ? a['nome'] as String
                        : 'Sem Nome';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: corVerdeEscuro.withOpacity(0.1),
                        child: const Icon(Icons.pets, color: corVerdeEscuro, size: 20),
                      ),
                      title: Text(
                        nomeAnimal,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Brinco: ${a['brinco']}'),
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        _vincularAnimal(a);
                      },
                    );
                  }).toList(),
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
    if (_carregando) {
      return const Scaffold(
        backgroundColor: corFundo,
        body: Center(
          child: CircularProgressIndicator(color: corVerdeEscuro),
        ),
      );
    }

    if (_analise == null) {
      return const Scaffold(
        backgroundColor: corFundo,
        body: Center(
          child: Text('Não foi possível carregar essa análise.'),
        ),
      );
    }

    final animalVinculado = _analise!['animal'] as Map<String, dynamic>?;
    final nomeAnimal = (animalVinculado?['nome'] as String?)?.isNotEmpty == true
        ? animalVinculado!['nome'] as String
        : 'Sem Nome';

    final status = _statusConfig;
    final corFundoStatus = status['corFundo'] as Color;
    final corBordaStatus = status['corBorda'] as Color;
    final corDestaqueStatus = status['corDestaque'] as Color;
    final iconeStatus = status['icone'] as IconData;
    final tituloStatus = status['titulo'] as String;
    final detalheStatus = status['detalhe'] as String;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corAppBar,
        elevation: 0,
        title: const Text(
          'Laudo de Análise',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do Exame
            Container(
              width: double.infinity,
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: corBorda)),
              ),
              child: Image.network(
                _analise!['imagem_url'] as String? ?? '',
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[100],
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 40, color: corTextoSecundario),
                      SizedBox(height: 8),
                      Text('Imagem indisponível', style: TextStyle(color: corTextoSecundario)),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card do Resultado da Análise
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: corFundoStatus,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corBordaStatus),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(iconeStatus, color: corDestaqueStatus, size: 28),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                tituloStatus,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: corDestaqueStatus,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detalheStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            color: corTextoPrimario,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: corBorda),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Confiança IA',
                                  style: TextStyle(fontSize: 12, color: corTextoSecundario),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_analise!['confianca']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: corTextoPrimario,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Data do Exame',
                                  style: TextStyle(fontSize: 12, color: corTextoSecundario),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatarData(_analise!['criado_em'] as String?),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: corTextoPrimario,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Vínculo Zootécnico
                  const Text(
                    'Vínculo Zootécnico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: corTextoPrimario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corBorda),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: corVerdeEscuro.withOpacity(0.08),
                          radius: 20,
                          child: const Icon(Icons.pets, color: corVerdeEscuro, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animalVinculado != null ? nomeAnimal : 'Nenhum animal vinculado',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: animalVinculado != null ? corTextoPrimario : corTextoSecundario,
                                ),
                              ),
                              if (animalVinculado != null)
                                Text(
                                  'Brinco: ${animalVinculado['brinco']}',
                                  style: const TextStyle(
                                    color: corTextoSecundario,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (animalVinculado != null)
                          IconButton(
                            icon: const Icon(Icons.link_off, size: 20, color: Colors.redAccent),
                            tooltip: 'Desvincular',
                            onPressed: _salvando ? null : _desvincularAnimal,
                          ),
                        TextButton(
                          onPressed: _salvando ? null : _mostrarSeletorDeAnimal,
                          child: Text(
                            animalVinculado != null ? 'Trocar' : 'Vincular',
                            style: const TextStyle(
                              color: corVerdeEscuro,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Observações Clínicas
                  const Text(
                    'Observações Clínicas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: corTextoPrimario,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _observacoesController,
                    maxLines: 4,
                    onChanged: (_) => setState(() => _alterado = true),
                    style: const TextStyle(color: corTextoPrimario, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Ex: Teste de caneca realizado. Prescrição médica...',
                      hintStyle: const TextStyle(color: corTextoSecundario, fontSize: 14),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: corBorda),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: corBorda),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: corVerdeEscuro, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Botão Salvar
                  if (_alterado)
                    ElevatedButton(
                      onPressed: _salvando ? null : _salvarObservacoes,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corVerdeEscuro,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _salvando ? 'Salvando...' : 'Salvar Observações',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}