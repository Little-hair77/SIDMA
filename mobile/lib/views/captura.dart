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
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corVerdeClaro = Color(0xFF74C319);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD); 
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF1E293B);

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
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum animal cadastrado corresponde a esse código.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _tirarFoto() async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, 
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

  // - LÓGICA DE CORES PARA O RESULTADO 
  Map<String, dynamic> get _configResultado {
    if (_resultadoIA == null) return {};
    final resultadoStr = (_resultadoIA!['resultado'] as String).toLowerCase();
    
    if (resultadoStr.contains('possível') || resultadoStr.contains('suspeita') || resultadoStr.contains('mastite')) {
      return {'corBase': Colors.redAccent.shade400, 'icone': Icons.error_outline, 'titulo': 'ALERTA DETECTADO'};
    } else if (resultadoStr.contains('adicional') || resultadoStr.contains('atenção')) {
      return {'corBase': Colors.orange.shade600, 'icone': Icons.warning_amber_rounded, 'titulo': 'ATENÇÃO NECESSÁRIA'};
    } else {
      return {'corBase': corVerdeEscuro, 'icone': Icons.check_circle_outline, 'titulo': 'LAUDO SAUDÁVEL'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      
      // APP BAR 
      appBar: AppBar(
        backgroundColor: corVerdeClaro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nova Análise',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
      ),
      
      body: Stack(
        children: [
          // MARCA D'ÁGUA
          Center(
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

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // - INSTRUÇÕES
                  const Text(
                    'Captura de Amostra',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: corTextoPrimario),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Posicione a amostra de leite em um local bem iluminado e evite sombras para garantir a precisão da Inteligência Artificial.',
                    style: TextStyle(color: Colors.black54, fontSize: 15, height: 1.4),
                  ),
                  const SizedBox(height: 24),

                  // - SELEÇÃO DE ANIMAL
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.pets, color: corAzulPrincipal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<dynamic>(
                              isExpanded: true,
                              value: _animalSelecionado,
                              hint: const Text('Vincular a um animal (opcional)', style: TextStyle(color: Colors.black54)),
                              items: _animais.map<DropdownMenuItem<dynamic>>((a) {
                                return DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a['nome']?.isNotEmpty == true ? '${a['nome']} (${a['brinco']})' : a['brinco'],
                                    style: const TextStyle(color: corTextoPrimario),
                                  ),
                                );
                              }).toList(),
                              onChanged: (valor) => setState(() => _animalSelecionado = valor),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code_scanner, color: corAzulPrincipal), // Retornado ao Azul
                          tooltip: 'Escanear QR Code do animal',
                          onPressed: _escanearAnimal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // - ÁREA DE EXIBIÇÃO DA IMAGEM 
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _imagem != null ? corAzulPrincipal.withOpacity(0.3) : Colors.grey.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _imagem != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.memory(_imagem!, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: CircleAvatar(
                                  backgroundColor: Colors.black54,
                                  child: IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.white),
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
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: corAzulPrincipal.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_outlined, size: 48, color: corAzulPrincipal),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nenhuma amostra capturada',
                                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque no botão abaixo para abrir a câmera',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),

                  // - MENSAGEM DE ERRO 
                  if (_erroAcesso != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                      ),
                      child: Text(_erroAcesso!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // - AÇÕES / ESTADO DE CARREGAMENTO / RESULTADO
                  if (_estaCarregando)
                    _ConstruirEstadoProcessamento()
                  else if (_resultadoIA != null)
                    _ConstruirCartaoResultado()
                  else ...[
                    if (_imagem == null)
                      OutlinedButton.icon(
                        onPressed: _tirarFoto,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('ABRIR CÂMERA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: corAzulPrincipal, // Retornado ao Azul Interativo
                          side: const BorderSide(color: corAzulPrincipal, width: 2),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),

                    if (_imagem != null)
                      ElevatedButton.icon(
                        onPressed: _analisarAmostra,
                        icon: const Icon(Icons.memory),
                        label: const Text('ANALISAR COM IA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: corVerdePrincipal, 
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          elevation: 4,
                          shadowColor: corVerdePrincipal.withOpacity(0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // - WIDGET: ESTADO DE PROCESSAMENTO 
  Widget _ConstruirEstadoProcessamento() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: corAzulPrincipal),
          const SizedBox(height: 20),
          const Text(
            'Processando Amostra...',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
          ),
          const SizedBox(height: 8),
          Text(
            'A Inteligência Artificial está analisando\npadrões visuais e coloração.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.4),
          ),
        ],
      ),
    );
  }

  // - WIDGET: CARTÃO DE RESULTADO
  Widget _ConstruirCartaoResultado() {
    final config = _configResultado;
    final cor = config['corBase'] as Color;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: cor.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(config['icone'], size: 56, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            config['titulo'],
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Text(
            _resultadoIA!['resultado'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.white30, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.analytics_outlined, size: 20, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Confiança (IA): ${_resultadoIA!['confianca']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(); 
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70, width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('CONCLUIR E VOLTAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}