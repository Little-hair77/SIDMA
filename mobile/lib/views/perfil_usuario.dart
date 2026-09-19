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

  // Paleta de Cores
  static const Color corVerdePrimaria   = Color(0xFF10B981);
  static const Color corAzulMarinho     = Color(0xFF1E293B); 
  static const Color corTextoPrimario   = Color(0xFF0F172A); 
  static const Color corTextoSecundario = Color(0xFF64748B); 
  static const Color corFundo           = Color(0xFFF8FAFC); 

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    // Tenta buscar os dados atualizados do servidor; se não conseguir (ex: sem internet),
    // cai para o cache salvo localmente no último login.
    final dadosServidor = await _apiService.buscarPerfil();
    final dados = dadosServidor ?? await _apiService.obterUsuarioSalvo();

    if (!mounted) return;
    setState(() {
      _nome = dados['nome']?.isNotEmpty == true ? dados['nome']! : 'Usuário SIDMA';
      _email = dados['email']?.isNotEmpty == true ? dados['email']! : 'E-mail não informado';
      _carregandoDados = false;
    });
  }

  void _mostrarIndisponivel(String recurso) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$recurso ainda não está disponível nesta versão.')),
    );
  }

  Future<void> _abrirEdicaoPerfil() async {
    final controladorNome = TextEditingController(text: _nome == 'Usuário SIDMA' ? '' : _nome);
    final controladorEmail = TextEditingController(text: _email == 'E-mail não informado' ? '' : _email);
    final chaveFormulario = GlobalKey<FormState>();
    bool salvando = false;

    final salvou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Perfil', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: chaveFormulario,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controladorNome,
                      decoration: const InputDecoration(labelText: 'Nome'),
                      validator: (valor) =>
                          (valor == null || valor.trim().isEmpty) ? 'Informe seu nome.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: controladorEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail.';
                        if (!valor.contains('@') || !valor.contains('.')) return 'E-mail inválido.';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: salvando ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: corTextoSecundario)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: corVerdePrimaria),
                  onPressed: salvando
                      ? null
                      : () async {
                          if (!chaveFormulario.currentState!.validate()) return;

                          setStateDialog(() => salvando = true);
                          final resultado = await _apiService.atualizarPerfil(
                            controladorNome.text.trim(),
                            controladorEmail.text.trim(),
                          );
                          setStateDialog(() => salvando = false);

                          if (!context.mounted) return;

                          if (resultado['sucesso'] == true) {
                            Navigator.of(context).pop(true);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(resultado['mensagem'] ?? 'Erro ao salvar perfil.')),
                            );
                          }
                        },
                  child: salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (salvou == true) {
      await _buscarDadosUsuario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso.')),
      );
    }
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: corVerdePrimaria),
                title: const Text('Tirar Foto'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: corVerdePrimaria),
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

  Future<void> _confirmarLogout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Aplicativo?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: corTextoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      _efetuarLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      
      // APP BAR 
      appBar: AppBar(
        backgroundColor: corAzulMarinho,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meu Perfil',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      
      body: _carregandoDados
          ? const Center(child: CircularProgressIndicator(color: corVerdePrimaria))
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
                            opacity: 0.03,
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
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
                                          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                                        ],
                                      ),
                                      child: CircleAvatar(
                                        radius: 54, 
                                        backgroundColor: corVerdePrimaria.withOpacity(0.12),
                                        backgroundImage: fotoBytes != null ? MemoryImage(fotoBytes) : null,
                                        child: fotoBytes == null
                                            ? const Icon(Icons.person, size: 54, color: corVerdePrimaria)
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2), 
                                        ),
                                        child: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: corVerdePrimaria,
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
                            const SizedBox(height: 18),

                            // - DADOS DO USUÁRIO 
                            Text(
                              _nome,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: corTextoPrimario),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: const TextStyle(fontSize: 14, color: corTextoSecundario),
                            ),
                            const SizedBox(height: 28),

                            // - CARD DE INFORMAÇÕES E CONFIGURAÇÕES
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                                ],
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildAcaoMenu(
                                          Icons.edit_outlined,
                                          'Editar Perfil',
                                          onTap: _abrirEdicaoPerfil,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Divider(height: 1, thickness: 0.5),
                                        _buildAcaoMenu(Icons.notifications_none, 'Notificações',
                                            onTap: () => _mostrarIndisponivel('Notificações')),
                                        _buildAcaoMenu(Icons.security, 'Segurança e Senha',
                                            onTap: () => _mostrarIndisponivel('Segurança e Senha')),
                                        _buildAcaoMenu(Icons.help_outline, 'Suporte SIDMA',
                                            onTap: () => _mostrarIndisponivel('Suporte SIDMA')),
                                        const Divider(height: 1, thickness: 0.5),
                                        _buildAcaoMenu(
                                          Icons.exit_to_app, 
                                          'Sair', 
                                          corPersonalizada: Colors.redAccent, 
                                          onTap: _confirmarLogout,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 32),
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
                        children: const [
                          Text(
                            'SIDMA • VERSÃO 1.0.0',
                            style: TextStyle(
                              color: corTextoSecundario,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Gestão Sanitária Inteligente',
                            style: TextStyle(
                              color: corTextoSecundario,
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

  // Widget auxiliar para os menus da base do card
  Widget _buildAcaoMenu(IconData icon, String titulo, {required VoidCallback onTap, Color? corPersonalizada}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: corPersonalizada ?? corTextoSecundario, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                titulo,
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: FontWeight.w500, 
                  color: corPersonalizada ?? corTextoPrimario,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right, 
              color: corPersonalizada?.withOpacity(0.5) ?? corTextoSecundario.withOpacity(0.6), 
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}