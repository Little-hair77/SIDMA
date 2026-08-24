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
  
  // Alterado: Agora guardamos o mapa completo da resposta para criar uma UI mais rica
  Map<String, dynamic>? _resultadoIA;
  String? _erroAcesso;

  List<dynamic> _animais = [];
  dynamic _animalSelecionado;

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Paleta de Cores
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
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
        SnackBar(content: Text('Animal identificado: ${animalEncontrado['brinco']}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum animal cadastrado corresponde a esse código.')),
      );
    }
  }

  // Função para abrir a câmera
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

  // Função para enviar a foto para a API
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

  // Helper para definir as cores do resultado
  Map<String, dynamic> get _configResultado {
    if (_resultadoIA == null) return {};
    final resultadoStr = (_resultadoIA!['resultado'] as String).toLowerCase();
    
    if (resultadoStr.contains('possível') || resultadoStr.contains('suspeita')) {
      return {'corBase': Colors.red, 'icone': Icons.error_outline, 'titulo': 'ALERTA'};
    } else if (resultadoStr.contains('adicional') || resultadoStr.contains('atenção')) {
      return {'corBase': Colors.orange, 'icone': Icons.warning_amber_rounded, 'titulo': 'ATENÇÃO'};
    } else {
      return {'corBase': Colors.green, 'icone': Icons.check_circle_outline, 'titulo': 'SAUDÁVEL'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: Colors.black12,
        iconTheme: const IconThemeData(color: corAzulPrincipal),
        title: const Text(
          'Nova Análise',
          style: TextStyle(
            color: corTextoPrimario,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- INSTRUÇÕES ---
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

              // --- SELEÇÃO DE ANIMAL (OPCIONAL) ---
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
                    Icon(Icons.pets, color: corVerdePrincipal),
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
                      icon: Icon(Icons.qr_code_scanner, color: corAzulPrincipal),
                      tooltip: 'Escanear QR Code do animal',
                      onPressed: _escanearAnimal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- ÁREA DE EXIBIÇÃO DA IMAGEM ---
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _imagem != null ? corAzulPrincipal.withOpacity(0.3) : Colors.grey.shade300,
                    width: 2,
                    // Se não tiver imagem, simula um tracejado (visualmente representado por borda mais clara)
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
                          // Botão sobreposto para refazer a foto facilmente
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

              // --- MENSAGEM DE ERRO ---
              if (_erroAcesso != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Text(_erroAcesso!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                ),
                const SizedBox(height: 16),
              ],

              // --- AÇÕES / ESTADO DE CARREGAMENTO / RESULTADO ---
              if (_estaCarregando)
                _ConstruirEstadoProcessamento()
              else if (_resultadoIA != null)
                _ConstruirCartaoResultado()
              else ...[
                // Mostrar botão de Capturar APENAS se ainda não tiver imagem
                if (_imagem == null)
                  OutlinedButton.icon(
                    onPressed: _tirarFoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('ABRIR CÂMERA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: corAzulPrincipal,
                      side: const BorderSide(color: corAzulPrincipal, width: 2),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                // Mostrar botão de Analisar APENAS se tiver imagem
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
    );
  }

  // --- WIDGET EXTRAÍDO: ESTADO DE PROCESSAMENTO ---
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

  // --- WIDGET EXTRAÍDO: CARTÃO DE RESULTADO ---
  Widget _ConstruirCartaoResultado() {
    final config = _configResultado;
    final cor = config['corBase'] as MaterialColor;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cor.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(color: cor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(config['icone'], size: 48, color: cor.shade700),
          const SizedBox(height: 12),
          Text(
            config['titulo'],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cor.shade800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            _resultadoIA!['resultado'],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: corTextoPrimario),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(
                'Grau de Confiança (IA): ${_resultadoIA!['confianca']}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Volta para o Dashboard após ver o resultado
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: corTextoPrimario,
              side: BorderSide(color: Colors.grey.shade400),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Concluir e Voltar'),
          ),
        ],
      ),
    );
  }
}