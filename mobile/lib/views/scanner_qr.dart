import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Retorna (via Navigator.pop) o texto bruto lido pela câmera, ou null se cancelado.
class TelaScannerQr extends StatefulWidget {
  const TelaScannerQr({Key? key}) : super(key: key);

  @override
  State<TelaScannerQr> createState() => _TelaScannerQrState();
}

class _TelaScannerQrState extends State<TelaScannerQr> {
  final MobileScannerController _controller = MobileScannerController();
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
    if (valor == null) return;
    _jaLeu = true;
    Navigator.of(context).pop(valor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código do animal'),
        backgroundColor: corAzulPrincipal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.flash_on), onPressed: () => _controller.toggleTorch()),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _aoDetectar),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'Aponte a câmera para o QR Code ou código de barras',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 14, shadows: [Shadow(blurRadius: 6, color: Colors.black.withOpacity(0.8))]),
            ),
          ),
        ],
      ),
    );
  }
}