import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class TelaScannerQr extends StatefulWidget {
  const TelaScannerQr({Key? key}) : super(key: key);

  @override
  State<TelaScannerQr> createState() => _TelaScannerQrState();
}

class _TelaScannerQrState extends State<TelaScannerQr> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _jaLeu = false;

  static const Color corAzulPrincipal = Color(0xFF0D6EFD);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aoDetectar(BarcodeCapture captura) {
    if (_jaLeu) return;
    final codigos = captura.barcodes;
    if (codigos.isEmpty) return;

    final valor = codigos.first.rawValue;
    if (valor == null || valor.isEmpty) return;

    _jaLeu = true;

    if (!mounted) return;
    Navigator.of(context).pop(valor);
  }

  @override
  Widget build(BuildContext context) {
    const double tamanhoQuadrado = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Escanear Código',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: corAzulPrincipal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              final bool estaLigada = state.torchState == TorchState.on;
              return IconButton(
                icon: Icon(
                  estaLigada ? Icons.flash_on : Icons.flash_off,
                  color: estaLigada ? Colors.yellow : Colors.white70,
                ),
                onPressed: () => _controller.toggleTorch(),
              );
            },
          ),
          // Botão de Troca de Câmera
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              return IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: () => _controller.switchCamera(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Câmera do Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _aoDetectar,
          ),

          // Máscara semi-transparente com janela central transparente
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.55),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: tamanhoQuadrado,
                    height: tamanhoQuadrado,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Moldura visual do quadrado de leitura
          Center(
            child: Container(
              width: tamanhoQuadrado,
              height: tamanhoQuadrado,
              decoration: BoxDecoration(
                border: Border.all(color: corAzulPrincipal, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Texto com instruções na parte inferior
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Posicione o QR Code ou código dentro do quadrado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
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