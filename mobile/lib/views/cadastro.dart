import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../navigation/nav.dart';

class TelaCadastro extends StatefulWidget {
  const TelaCadastro({Key? key}) : super(key: key);

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  // Paleta de Cores
  static const Color corAzulPrincipal = Color(0xFF0D6EFD); 
  static const Color corVerdePrincipal = Color(0xFF74C319); 
  static const Color corTextoPrimario = Color(0xFF1E293B); 
  static const Color corFundo = Colors.white; 

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _criarConta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _apiService.registrar(
        _nomeController.text.trim(),
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;

      if (resultado['sucesso'] == true) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TelaPrincipal()),
        );
      } else {
        setState(() {
          _erro = resultado['mensagem'];
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Ocorreu um erro ao criar a conta. Tente novamente.';
        _carregando = false;
      });
    }
  }

  // Helper para criar o estilo dos campos de texto (idêntico à Tela de Login)
  InputDecoration _estiloCampo({required String rotulo, required IconData iconePrefixo, Widget? iconeSufixo}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(iconePrefixo, color: corAzulPrincipal),
      suffixIcon: iconeSufixo,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: corAzulPrincipal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corAzulPrincipal,
          primary: corAzulPrincipal,
          secondary: corVerdePrincipal,
          background: corFundo,
        ),
        // textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: corFundo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- CABEÇALHO (IDÊNTICO À TELA DE LOGIN) ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Image.asset(
                          'assets/images/logoSIDMA-2.png', 
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      Text(
                        'SIDMA',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: corAzulPrincipal,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Sistema Inteligente de Auxílio\nao Diagnóstico de Mastite',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 48), // Espaçamento antes do form

                      // --- CAMPOS DE ENTRADA (ESTILIZADOS) ---
                      TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(
                          rotulo: 'Nome completo profissional',
                          iconePrefixo: Icons.person_outline,
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) return 'Informe seu nome';
                          if (valor.trim().split(' ').length < 2) return 'Informe nome e sobrenome';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(
                          rotulo: 'E-mail',
                          iconePrefixo: Icons.email_outlined,
                        ),
                        validator: (valor) {
                          if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail';
                          if (!valor.contains('@')) return 'Formato de e-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(
                          rotulo: 'Senha',
                          iconePrefixo: Icons.lock_outline,
                          iconeSufixo: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (valor) {
                          if (valor == null || valor.isEmpty) return 'Informe sua senha';
                          if (valor.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _confirmarSenhaController,
                        obscureText: !_senhaVisivel, // Segue a mesma visibilidade da senha
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(
                          rotulo: 'Confirmar senha',
                          iconePrefixo: Icons.lock_reset_outlined,
                        ),
                        validator: (valor) {
                          if (valor != _senhaController.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32), // Espaçamento maior antes do botão ação

                      // --- BOTÃO DE AÇÃO ---
                      if (_carregando)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: _criarConta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrincipal, 
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text(
                            'CRIAR CONTA',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // --- VOLTAR PARA LOGINO) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Já tem uma conta?', style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(foregroundColor: corAzulPrincipal),
                              child: const Text(
                                'Entrar agora',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // --- ÁREA DE ERRO ---
                      if (_erro != null) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent, width: 0.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _erro!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}