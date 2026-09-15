import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'scanner_qr.dart';

class TelaCaptura extends StatefulWidget {
  const TelaCaptura({Key? key}) : super(key: key);

  @override
  State<TelaCaptura> createState() => _TelaCapturaState();
}

class _TelaCapturaState extends State<TelaCaptura> {
  Uint8List? _imagem;
  String? _nomeArquivo;
  bool _estaCarregando = false;

  Map<String, dynamic>? _resultadoIA;
  String? _erroAcesso;

  List<dynamic> _animais = [];
  dynamic _animalSelecionado;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Paleta de Cores
  static const Color corFundoDark = Color(0xFF111827);
  static const Color corCardDark = Color(0xFF1F2937);
  static const Color corBordaDark = Color(0xFF374151);    
  static const Color corTextoClaro = Color(0xFFF9FAFB);
  static const Color corTextoSecundario = Color(0xFF9CA3AF); 
  static const Color corVerdeEscuro = Color(0xFF1DB156);
  static const Color corVerdeClaro = Color(0xFF74C319); 

  @override
  void initState() {
    super.initState();
    _carregarAnimais();
  }

  Future<void> _carregarAnimais() async {
    final lista = await _apiService.listarAnimais();
    if (mounted) setState(() => _animais = lista ?? []);
  }

  Future<void> _escanearAnimal() async {
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

    if (!mounted) return;

    if (animalEncontrado != null) {
      setState(() => _animalSelecionado = animalEncontrado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animal identificado: ${animalEncontrado['brinco']}'),
          backgroundColor: corVerdeEscuro,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nenhum animal cadastrado corresponde a esse código.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (foto != null) {
        final bytes = await foto.readAsBytes();
        setState(() {
          _imagem = bytes;
          _nomeArquivo = foto.name;
          _resultadoIA = null;
          _erroAcesso = null;
        });
      }
    } catch (e) {
      setState(() {
        _erroAcesso = "Não foi possível acessar a câmera. Verifique as permissões.";
      });
    }
  }

  Future<void> _analisarAmostra() async {
    if (_imagem == null) return;

    setState(() {
      _estaCarregando = true;
      _erroAcesso = null;
    });

    final resposta = await _apiService.enviarAnaliseLeite(
      _imagem!,
      _nomeArquivo ?? 'amostra.jpg',
      animalId: _animalSelecionado?['id'],
    );

    setState(() {
      _estaCarregando = false;
      if (resposta != null && resposta['status'] == 'sucesso') {
        _resultadoIA = resposta;
      } else {
        _erroAcesso = "Erro de comunicação com o servidor IA. Tente novamente.";
      }
    });
  }

  Map<String, dynamic> get _configResultado {
    if (_resultadoIA == null) return {};
    final resultadoStr = (_resultadoIA!['resultado'] as String).toLowerCase();

    if (resultadoStr.contains('possível') || resultadoStr.contains('suspeita') || resultadoStr.contains('mastite')) {
      return {'corBase': Colors.redAccent.shade400, 'icone': Icons.error_outline, 'titulo': 'ALERTA DETECTADO'};
    } else if (resultadoStr.contains('adicional') || resultadoStr.contains('atenção')) {
      return {'corBase': Colors.orange.shade700, 'icone': Icons.warning_amber_rounded, 'titulo': 'ATENÇÃO NECESSÁRIA'};
    } else {
      return {'corBase': corVerdeEscuro, 'icone': Icons.check_circle_outline, 'titulo': 'LAUDO SAUDÁVEL'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundoDark,
      appBar: AppBar(
        backgroundColor: corFundoDark,
        foregroundColor: corTextoClaro,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Nova Análise',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: corTextoClaro),
        ),
      ),
      body: Stack(
        children: [
          // Marca D'Água sutil em fundo escuro
          Center(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/logoSIDMA-2.png',
                width: 260,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.pets, size: 200, color: Colors.white24),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e Descrição
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: corVerdeEscuro.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: corVerdeClaro, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Captura de Amostra',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: corTextoClaro,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Posicione a amostra de leite em um local bem iluminado e evite sombras para garantir a precisão da Inteligência Artificial.',
                    style: TextStyle(
                      fontSize: 14,
                      color: corTextoSecundario,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Seletor de Animal em Card Escuro
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: corCardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: corBordaDark),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets, color: corVerdeClaro, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<dynamic>(
                              dropdownColor: corCardDark,
                              isExpanded: true,
                              value: _animalSelecionado,
                              hint: const Text(
                                'Vincular a um animal (opcional)',
                                style: TextStyle(color: corTextoSecundario, fontSize: 14),
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: corTextoSecundario),
                              items: _animais.map<DropdownMenuItem<dynamic>>((a) {
                                return DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a['nome']?.isNotEmpty == true ? '${a['nome']} (${a['brinco']})' : a['brinco'],
                                    style: const TextStyle(color: corTextoClaro, fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (valor) => setState(() => _animalSelecionado = valor),
                            ),
                          ),
                        ),
                        Material(
                          color: corVerdeEscuro.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: corVerdeClaro, size: 22),
                            tooltip: 'Escanear QR Code do animal',
                            onPressed: _escanearAnimal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Container de Exibição da Imagem em Fundo Escuro
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: corCardDark,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _imagem != null ? corVerdeEscuro : corBordaDark,
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: _imagem != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imagem!, fit: BoxFit.cover),
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black.withOpacity(0.7),
                                    child: IconButton(
                                      icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                                      onPressed: _tirarFoto,
                                      tooltip: 'Tirar nova foto',
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    color: corVerdeEscuro.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt_outlined, size: 48, color: corVerdeClaro),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nenhuma amostra capturada',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: corTextoClaro,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Toque no botão abaixo para abrir a câmera',
                                  style: TextStyle(fontSize: 13, color: corTextoSecundario),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mensagem de Erro (se houver)
                  if (_erroAcesso != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _erroAcesso!,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Botões de Ação Escuros / Verdes
                  if (_estaCarregando)
                    _construirEstadoProcessamento()
                  else if (_resultadoIA != null)
                    _construirCartaoResultado()
                  else ...[
                    if (_imagem == null)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _tirarFoto,
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          label: const Text(
                            'ABRIR CÂMERA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdeEscuro,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),

                    if (_imagem != null) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _analisarAmostra,
                          icon: const Icon(Icons.memory, color: Colors.white),
                          label: const Text(
                            'ANALISAR COM IA',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdeClaro,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _tirarFoto,
                          icon: const Icon(Icons.refresh, color: corTextoClaro),
                          label: const Text(
                            'TIRAR OUTRA FOTO',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: corTextoClaro,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: corBordaDark, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _construirEstadoProcessamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corCardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: corBordaDark),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: corVerdeClaro),
          SizedBox(height: 20),
          Text(
            'Processando Amostra...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoClaro),
          ),
          SizedBox(height: 8),
          Text(
            'A Inteligência Artificial está analisando\npadrões visuais e coloração da amostra.',
            textAlign: TextAlign.center,
            style: TextStyle(color: corTextoSecundario, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _construirCartaoResultado() {
    final config = _configResultado;
    final cor = config['corBase'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: corCardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cor, width: 2),
      ),
      child: Column(
        children: [
          Icon(config['icone'], size: 56, color: cor),
          const SizedBox(height: 12),
          Text(
            config['titulo'],
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cor,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _resultadoIA!['resultado'] ?? 'Sem dados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: corTextoClaro),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: corBordaDark, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 20, color: corTextoSecundario),
              const SizedBox(width: 8),
              Text(
                'Confiança (IA): ${_resultadoIA!['confianca'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: corTextoClaro),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: corTextoClaro,
                side: const BorderSide(color: corBordaDark, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('CONCLUIR E VOLTAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}