import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/cores.dart';

class TelaQrCodeAnimal extends StatelessWidget {
  final dynamic animal;

  const TelaQrCodeAnimal({Key? key, required this.animal}) : super(key: key);

  static const Color corQrOlhos = Color(0xFF0D6EFD);
  static const Color corQrDados = Color(0xFF1E293B);

  String get _conteudoQr => 'SIDMA-ANIMAL|${animal['id']}|${animal['brinco']}';

  @override
  Widget build(BuildContext context) {
    final cores = AppColors.of(context);

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: AppBar(
        backgroundColor: cores.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        iconTheme: IconThemeData(color: cores.primario),
        title: Text('QR Code do Animal', style: TextStyle(color: cores.textoPrimario, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
                  ],
                ),
                child: QrImageView(
                  data: _conteudoQr,
                  version: QrVersions.auto,
                  size: 240,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: corQrOlhos),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: corQrDados),
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                animal['nome']?.isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cores.textoPrimario),
              ),
              const SizedBox(height: 4),
              Text('Brinco: ${animal['brinco']}', style: TextStyle(color: cores.textoSecundario)),
              const SizedBox(height: 24),
              Text(
                'Imprima ou tire uma foto deste código e cole no brinco/etiqueta do animal. '
                'Ao escanear na tela de análise, o animal será identificado automaticamente.',
                textAlign: TextAlign.center,
                style: TextStyle(color: cores.textoSecundario, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}