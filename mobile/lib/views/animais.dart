import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cadastro_animal.dart';
import 'qrCode_animal.dart';

class TelaAnimais extends StatefulWidget {
  const TelaAnimais({Key? key}) : super(key: key);

  @override
  State<TelaAnimais> createState() => _TelaAnimaisState();
}

class _TelaAnimaisState extends State<TelaAnimais> {
  final ApiService _apiService = ApiService();
  List<dynamic> _animais = [];
  bool _carregando = true;

  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await _apiService.listarAnimais();
    setState(() {
      _animais = lista ?? [];
      _carregando = false;
    });
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
          'Meu Rebanho',
          style: TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: corVerdePrincipal,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TelaCadastroAnimal()),
          );
          _carregar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
          : _animais.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets_outlined, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        const Text(
                          'Nenhum animal cadastrado',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque no "+" para adicionar o primeiro animal do rebanho.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: corAzulPrincipal,
                  onRefresh: _carregar,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _animais.length,
                    itemBuilder: (context, index) {
                      final animal = _animais[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: CircleAvatar(
                            backgroundColor: corVerdePrincipal.withOpacity(0.12),
                            child: Icon(Icons.pets, color: corVerdePrincipal),
                          ),
                          title: Text(
                            animal['nome']?.isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario),
                          ),
                          subtitle: Text(
                            'Brinco: ${animal['brinco']} · ${animal['total_analises']} análise(s)',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.qr_code, color: corAzulPrincipal),
                            tooltip: 'Ver QR Code',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => TelaQrCodeAnimal(animal: animal)),
                              );
                            },
                          ),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: animal)),
                            );
                            _carregar();
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
