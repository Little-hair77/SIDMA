import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class TelaCaptura extends StatefulWidget {
  const TelaCaptura({Key? key}) : super(key: key);

  @override
  State<TelaCaptura> createState() => _TelaCapturaState();
}

class _TelaCapturaState extends State<TelaCaptura> {
  Uint8List? _imagem;
  String? _nomeArquivo;
  bool _estaCarregando = false;
  String _resultadoIA = '';

  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  // Função para abrir a câmera
  Future<void> _tirarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80, // Comprime levemente para não pesar no envio (3G/4G rural)
    );

    if (foto != null) {
      final bytes = await foto.readAsBytes();
      setState(() {
        _imagem = bytes;
        _nomeArquivo = foto.name;
        _resultadoIA = ''; // Limpa o resultado anterior, se houver
      });
    }
  }

  // Função para enviar a foto para a API
  Future<void> _analisarAmostra() async {
    if (_imagem == null) return;

    setState(() {
      _estaCarregando = true;
    });

    // Chama o serviço que configuramos com o Dio
    final resposta = await _apiService.enviarAnaliseLeite(_imagem!, _nomeArquivo ?? 'amostra.jpg');

    setState(() {
      _estaCarregando = false;
      if (resposta != null && resposta['status'] == 'sucesso') {
        // Formata o resultado na tela
        _resultadoIA = "${resposta['resultado']} \nConfiança: ${resposta['confianca']}";
      } else {
        _resultadoIA = "Erro ao processar imagem. Tente novamente.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análise de Mastite'),
        backgroundColor: Colors.teal, // Cor que remete ao campo/saúde
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Área de exibição da imagem ou placeholder
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _imagem != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(_imagem!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('Nenhuma amostra capturada', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
              const SizedBox(height: 24),

              // Botões de Ação
              if (!_estaCarregando) ...[
                ElevatedButton.icon(
                  onPressed: _tirarFoto,
                  icon: const Icon(Icons.camera),
                  label: const Text('Capturar Amostra'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Só mostra o botão de analisar se já houver uma foto tirada
                if (_imagem != null)
                  ElevatedButton.icon(
                    onPressed: _analisarAmostra,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analisar com IA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
              ] else
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('A IA está analisando a imagem...'),
                  ],
                ),

              const SizedBox(height: 24),

              // Exibição do Resultado
              if (_resultadoIA.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _resultadoIA.contains('Erro') ? Colors.red[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _resultadoIA,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}