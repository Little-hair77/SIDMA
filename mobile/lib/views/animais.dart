import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'cadastro_animal.dart';
import 'qrCode_animal.dart';
import 'detalhe_animal.dart'; 

class TelaAnimais extends StatefulWidget {
  const TelaAnimais({Key? key}) : super(key: key);

  @override
  State<TelaAnimais> createState() => _TelaAnimaisState();
}

class _TelaAnimaisState extends State<TelaAnimais> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _animais = [];
  List<dynamic> _animaisFiltrados = []; 
  
  bool _carregando = true;
  final TextEditingController _buscaController = TextEditingController();

  // PALETA DE CORES
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86); 
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final lista = await _apiService.listarAnimais();
    if (!mounted) return;
    setState(() {
      _animais = lista ?? [];
      _animaisFiltrados = _animais; 
      _carregando = false;
    });
  }

  void _filtrarAnimais(String termo) {
    if (termo.isEmpty) {
      setState(() => _animaisFiltrados = _animais);
      return;
    }
    
    final termoBusca = termo.toLowerCase();
    setState(() {
      _animaisFiltrados = _animais.where((animal) {
        final nome = (animal['nome'] ?? '').toString().toLowerCase();
        final brinco = (animal['brinco'] ?? '').toString().toLowerCase();
        return nome.contains(termoBusca) || brinco.contains(termoBusca);
      }).toList();
    });
  }

  Future<void> _confirmarExclusao(dynamic animal) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Animal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja remover o animal brinco ${animal['brinco']} do rebanho? Todo o histórico de análises será perdido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _carregando = true);
      // await _apiService.excluirAnimal(animal['id']);
      await Future.delayed(const Duration(milliseconds: 500)); 
      _carregar();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Animal removido com sucesso.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      
      // APP BAR VERDE ARREDONDADO (Design System)
      appBar: AppBar(
        backgroundColor: corVerdeEscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meu Rebanho',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
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
      
      body: Stack(
        children: [
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
          
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _buscaController,
                  onChanged: _filtrarAnimais,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou brinco...',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    prefixIcon: const Icon(Icons.search, color: corVerdeEscuro),
                    suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _buscaController.clear();
                              _filtrarAnimais('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: corVerdeEscuro, width: 1.5),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
                    : _animais.isEmpty
                        ? _buildEmptyState('Nenhum animal cadastrado', 'Toque no "+" para adicionar o primeiro animal do rebanho.')
                        : _animaisFiltrados.isEmpty
                            ? _buildEmptyState('Nenhum resultado encontrado', 'Tente buscar por outro nome ou número de brinco.')
                            : RefreshIndicator(
                                color: corVerdePrincipal,
                                onRefresh: _carregar,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _animaisFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final animal = _animaisFiltrados[index];
                                    
                                    final bool emCarencia = animal['em_carencia'] == true;
                                    final bool alertaReincidencia = animal['alerta_reincidencia'] == true;

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
                                        contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 8),
                                        
                                        leading: CircleAvatar(
                                          radius: 26, 
                                          backgroundColor: corFundo,
                                          backgroundImage: animal['foto'] != null 
                                              ? NetworkImage(animal['foto']) 
                                              : null,
                                          child: animal['foto'] == null
                                              ? const Icon(Icons.pets, color: Colors.grey)
                                              : null,
                                        ),

                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                animal['nome']?.isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario, fontSize: 16),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (emCarencia || alertaReincidencia)
                                              const Padding(
                                                padding: EdgeInsets.only(left: 8.0),
                                                child: Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                                              ),
                                          ],
                                        ),
                                        
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            'Brinco: ${animal['brinco']} · ${animal['total_analises'] ?? 0} análise(s)',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                          ),
                                        ),
                                        
                                        trailing: PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                                          color: Colors.white,
                                          surfaceTintColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          onSelected: (value) async {
                                            if (value == 'visualizar') {
                                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)));
                                              _carregar();
                                            } else if (value == 'editar') {
                                              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: animal)));
                                              _carregar();
                                            } else if (value == 'qrcode') {
                                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaQrCodeAnimal(animal: animal)));
                                            } else if (value == 'excluir') {
                                              _confirmarExclusao(animal);
                                            }
                                          },
                                          itemBuilder: (BuildContext context) => [
                                            const PopupMenuItem(
                                              value: 'visualizar',
                                              child: Row(children: [Icon(Icons.visibility_outlined, size: 20, color: corAzulPrincipal), SizedBox(width: 12), Text('Ver Ficha')]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'editar',
                                              child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: Colors.black87), SizedBox(width: 12), Text('Editar')]),
                                            ),
                                            const PopupMenuItem(
                                              value: 'qrcode',
                                              child: Row(children: [Icon(Icons.qr_code, size: 20, color: Colors.black87), SizedBox(width: 12), Text('QR Code')]),
                                            ),
                                            const PopupMenuDivider(),
                                            const PopupMenuItem(
                                              value: 'excluir',
                                              child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), SizedBox(width: 12), Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                                            ),
                                          ],
                                        ),
                                        
                                        onTap: () async {
                                          await Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)),
                                          );
                                          _carregar(); 
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String titulo, String subtitulo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}