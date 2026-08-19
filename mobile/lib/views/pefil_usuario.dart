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

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final dados = await _apiService.obterUsuarioSalvo();
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
        UsuarioEstado.atualizarFoto(bytes); // Atualiza o estado global
      }
    } catch (e) {
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
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.azulPrincipal),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: AppColors.azulPrincipal),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(color: AppColors.textoPrimario, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _carregandoDados
          ? const Center(child: CircularProgressIndicator(color: AppColors.azulPrincipal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // --- AVATAR INTERATIVO COM VALUENOTIFIER ---
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
                              radius: 64,
                              backgroundColor: AppColors.azulPrincipal.withOpacity(0.1),
                              backgroundImage: fotoBytes != null ? MemoryImage(fotoBytes) : null,
                              child: fotoBytes == null
                                  ? const Icon(Icons.person, size: 64, color: AppColors.azulPrincipal)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.verdePrincipal,
                              child: IconButton(
                                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                onPressed: _mostrarOpcoesFoto,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // --- DADOS DO USUÁRIO ---
                  Text(
                    _nome,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textoPrimario),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 36),

                  // --- CARD DE INFORMAÇÕES ADICIONAIS DO PROJETO ---
                  Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildInfoTile(Icons.assignment_ind_outlined, 'Cargo', 'Técnico Agrícola / Veterinário'),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoTile(Icons.verified_user_outlined, 'Nível de Acesso', 'Administrador do Rebanho'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- BOTÃO LOGOUT ---
                  OutlinedButton.icon(
                    onPressed: _efetuarLogout,
                    icon: const Icon(Icons.logout_outlined, color: Colors.redAccent),
                    label: const Text(
                      'LOGOUT',
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Colors.redAccent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.azulPrincipal.withOpacity(0.7)),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textoPrimario)),
          ],
        ),
      ],
    );
  }
}