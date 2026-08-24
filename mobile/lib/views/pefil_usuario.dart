import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/cores.dart';
import '../core/usuario_estado.dart';
import '../services/api_service.dart';
import 'login.dart';

class TelaPerfilUsuario extends StatefulWidget {
  const TelaPerfilUsuario({Key? key}) : super(key: key);

  @override
  State<TelaPerfilUsuario> createState() => _TelaPerfilUsuarioState();
}

class _TelaPerfilUsuarioState extends State<TelaPerfilUsuario> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  String _nome = 'Carregando...';
  String _email = 'Carregando...';
  bool _carregandoDados = true;

  // - PALETA DE CORES
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corVerdePrincipal = Color(0xFF74C319);

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final dados = await _apiService.obterUsuarioSalvo();
    if (!mounted) return;
    setState(() {
      _nome = dados['nome']?.isNotEmpty == true ? dados['nome']! : 'Usuário SIDMA';
      _email = dados['email']?.isNotEmpty == true ? dados['email']! : 'E-mail não informado';
      _carregandoDados = false;
    });
  }

  Future<void> _alterarFoto(ImageSource fonte) async {
    try {
      final XFile? arquivo = await _picker.pickImage(
        source: fonte,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (arquivo != null) {
        final bytes = await arquivo.readAsBytes();
        UsuarioEstado.atualizarFoto(bytes); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao selecionar imagem.')),
      );
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Foto de Perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textoPrimario),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: corVerdeEscuro),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: corVerdeEscuro),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.gallery);
                },
              ),
              if (UsuarioEstado.fotoPerfilNotifier.value != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover Foto Atual', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    UsuarioEstado.removerFoto();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _efetuarLogout() async {
    await _apiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TelaLogin()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      
      // APP BAR 
      appBar: AppBar(
        backgroundColor: corVerdeEscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
      ),
      
      body: _carregandoDados
          ? const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      // Marca d'água de fundo
                      Positioned.fill(
                        child: Center(
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
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          children: [
                            ValueListenableBuilder<Uint8List?>(
                              valueListenable: UsuarioEstado.fotoPerfilNotifier,
                              builder: (context, fotoBytes, child) {
                                return Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 56, 
                                        backgroundColor: corVerdeEscuro.withOpacity(0.1),
                                        backgroundImage: fotoBytes != null ? MemoryImage(fotoBytes) : null,
                                        child: fotoBytes == null
                                            ? const Icon(Icons.person, size: 56, color: corVerdeEscuro)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2), // Borda para separar da foto
                                        ),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: corVerdePrincipal,
                                          child: IconButton(
                                            icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                                            onPressed: _mostrarOpcoesFoto,
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),

                            // - DADOS DO USUÁRIO 
                            Text(
                              _nome,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textoPrimario),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 32),

                            // - CARD DE INFORMAÇÕES E CONFIGURAÇÕES
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        _buildInfoTile(Icons.assignment_ind_outlined, 'Cargo/Função', 'Produtor / Gestor'),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(vertical: 8.0),
                                          child: Divider(height: 16, thickness: 0.5),
                                        ),
                                        _buildInfoTile(Icons.verified_user_outlined, 'Nível de Acesso', 'Administrador'),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildAcaoMenu(Icons.notifications_none, 'Notificações', onTap: () {}),
                                        _buildAcaoMenu(Icons.security, 'Segurança e Senha', onTap: () {}),
                                        _buildAcaoMenu(Icons.help_outline, 'Suporte SIDMA', onTap: () {}),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),

                            // - BOTÃO LOGOUT
                            OutlinedButton.icon(
                              onPressed: _efetuarLogout,
                              icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
                              label: const Text(
                                'SAIR DO APLICATIVO',
                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.red.shade50,
                                minimumSize: const Size(double.infinity, 56),
                                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // RODAPÉ (FOOTER)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SIDMA • VERSÃO 1.0.0',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Gestão Sanitária Inteligente',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Widget auxiliar para os dados do topo do card
  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: corVerdeEscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: corVerdeEscuro, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textoPrimario)),
          ],
        ),
      ],
    );
  }

  // Widget auxiliar para os menus da base do card
  Widget _buildAcaoMenu(IconData icon, String titulo, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textoPrimario),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }
}