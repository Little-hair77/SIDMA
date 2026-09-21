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
  static const Color corFundoDark = Color(0xFF0F172A); // Slate 900
  static const Color corCardDark = Color(0xFF1E293B); // Slate 800
  static const Color corBordaDark = Color(0xFF334155); // Slate 700
  static const Color corTextoClaro = Color(0xFFF8FAFC); // Slate 50
  static const Color corTextoSecundario = Color(0xFF94A3B8); // Slate 400
  
  // Cor de Destaque / Ação (Verde Esmeralda Moderado e Moderno)
  static const Color corPrimary = Color(0xFF10B981); 
  static const Color corPrimaryHover = Color(0xFF059669);

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
          backgroundColor: corPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nenhum animal cadastrado corresponde a esse código.'),
          backgroundColor: Colors.amber.shade900,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      return {'corBase': const Color(0xFFEF4444), 'icone': Icons.error_outline, 'titulo': 'ALERTA DETECTADO'};
    } else if (resultadoStr.contains('adicional') || resultadoStr.contains('atenção')) {
      return {'corBase': const Color(0xFFF59E0B), 'icone': Icons.warning_amber_rounded, 'titulo': 'ATENÇÃO NECESSÁRIA'};
    } else {
      return {'corBase': corPrimary, 'icone': Icons.check_circle_outline, 'titulo': 'LAUDO SAUDÁVEL'};
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
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: corTextoClaro),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho Clean
              const Text(
                'Captura de Amostra',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: corTextoClaro,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Posicione a amostra em um local bem iluminado para garantir a precisão da análise.',
                style: TextStyle(
                  fontSize: 14,
                  color: corTextoSecundario,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Seletor de Animal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: corCardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: corBordaDark),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets_outlined, color: corTextoSecundario, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<dynamic>(
                          dropdownColor: corCardDark,
                          isExpanded: true,
                          value: _animalSelecionado,
                          hint: const Text(
                            'Vincular animal (opcional)',
                            style: TextStyle(color: corTextoSecundario, fontSize: 14),
                          ),
                          icon: const Icon(Icons.keyboard_arrow_down, color: corTextoSecundario),
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
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: corTextoClaro, size: 20),
                      tooltip: 'Escanear QR Code',
                      onPressed: _escanearAnimal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Área de Exibição / Captura da Imagem
              GestureDetector(
                onTap: _imagem == null ? _tirarFoto : null,
                child: Container(
                  width: double.infinity,
                  height: 260,
                  decoration: BoxDecoration(
                    color: corCardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _imagem != null ? corPrimary : corBordaDark,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _imagem != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(_imagem!, fit: BoxFit.cover),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black.withOpacity(0.6),
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                                    onPressed: _tirarFoto,
                                    tooltip: 'Tirar outra foto',
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo_outlined, size: 40, color: corTextoSecundario),
                              SizedBox(height: 12),
                              Text(
                                'Tirar Foto da Amostra',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: corTextoClaro,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toque para abrir a câmera',
                                style: TextStyle(fontSize: 13, color: corTextoSecundario),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Feedback de Erro
              if (_erroAcesso != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _erroAcesso!,
                          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Estado / Botões
              if (_estaCarregando)
                _construirEstadoProcessamento()
              else if (_resultadoIA != null)
                _construirCartaoResultado()
              else ...[
                if (_imagem == null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _tirarFoto,
                      icon: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        'ABRIR CÂMERA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                if (_imagem != null) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _analisarAmostra,
                      icon: const Icon(Icons.auto_awesome_outlined, color: Colors.white, size: 20),
                      label: const Text(
                        'ANALISAR COM IA',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: TextButton.icon(
                      onPressed: _tirarFoto,
                      icon: const Icon(Icons.refresh, color: corTextoSecundario, size: 18),
                      label: const Text(
                        'Refazer Foto',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: corTextoSecundario,
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
    );
  }

  Widget _construirEstadoProcessamento() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBordaDark),
      ),
      child: Column(
        children: const [
          SizedBox(
            height: 28,
            width: 28,
            child: CircularProgressIndicator(color: corPrimary, strokeWidth: 2.5),
          ),
          SizedBox(height: 16),
          Text(
            'Processando Amostra',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: corTextoClaro),
          ),
          SizedBox(height: 4),
          Text(
            'A IA está analisando a amostra...',
            style: TextStyle(color: corTextoSecundario, fontSize: 13),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: corCardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(config['icone'], size: 44, color: cor),
          const SizedBox(height: 10),
          Text(
            config['titulo'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _resultadoIA!['resultado'] ?? 'Sem dados',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: corTextoClaro),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: corBordaDark, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 18, color: corTextoSecundario),
              const SizedBox(width: 6),
              Text(
                'Confiança: ${_resultadoIA!['confianca'] ?? 'N/A'}',
                style: const TextStyle(fontSize: 14, color: corTextoSecundario),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: corTextoClaro,
                side: const BorderSide(color: corBordaDark),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Concluir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}