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
  static const Color corVerdePrimaria   = Color(0xFF10B981); 
  static const Color corAzulMarinho     = Color(0xFF1E293B); 
  static const Color corTextoPrimario   = Color(0xFF0F172A); 
  static const Color corTextoSecundario = Color(0xFF64748B); 
  static const Color corCampoFundo      = Color(0xFFF1F5F9); 
  static const Color corFundo           = Color(0xFFF8FAFC); 

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

  InputDecoration _estiloCampo({
    required String rotulo, 
    required IconData iconePrefixo, 
    Widget? iconeSufixo,
  }) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 14),
      prefixIcon: Icon(iconePrefixo, color: corTextoSecundario, size: 22),
      suffixIcon: iconeSufixo,
      filled: true,
      fillColor: corCampoFundo,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: corVerdePrimaria, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corVerdePrimaria,
          primary: corVerdePrimaria,
          secondary: corAzulMarinho,
          surface: corFundo,
        ),
      ),
      child: Scaffold(
        backgroundColor: corFundo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // - CABEÇALHO 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Image.asset(
                          'assets/images/logoSIDMA-2.png', 
                          height: 110,
                          fit: BoxFit.contain,
                        ),
                      ),
                      
                      const Text(
                        'SIDMA',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: corAzulMarinho,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sistema Inteligente de Auxílio\nao Diagnóstico de Mastite',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: corTextoSecundario,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // - CAMPOS DE ENTRADA 
                      TextFormField(
                        controller: _nomeController,
                        style: const TextStyle(color: corTextoPrimario, fontSize: 15),
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
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: corTextoPrimario, fontSize: 15),
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
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _senhaController,
                        obscureText: !_senhaVisivel,
                        style: const TextStyle(color: corTextoPrimario, fontSize: 15),
                        decoration: _estiloCampo(
                          rotulo: 'Senha',
                          iconePrefixo: Icons.lock_outline,
                          iconeSufixo: IconButton(
                            icon: Icon(
                              _senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: corTextoSecundario,
                              size: 22,
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
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmarSenhaController,
                        obscureText: !_senhaVisivel,
                        style: const TextStyle(color: corTextoPrimario, fontSize: 15),
                        decoration: _estiloCampo(
                          rotulo: 'Confirmar senha',
                          iconePrefixo: Icons.lock_reset_outlined,
                        ),
                        validator: (valor) {
                          if (valor != _senhaController.text) return 'As senhas não coincidem';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // - BOTÃO DE AÇÃO
                      if (_carregando)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: corVerdePrimaria),
                        )
                      else ...[
                        ElevatedButton(
                          onPressed: _criarConta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrimaria, 
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'CRIAR CONTA',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // - VOLTAR PARA LOGIN 
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Já tem uma conta?', style: TextStyle(color: corTextoSecundario, fontSize: 14)),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: corAzulMarinho,
                                padding: const EdgeInsets.only(left: 6),
                              ),
                              child: const Text(
                                'Entrar agora',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // - ÁREA DE ERRO 
                      if (_erro != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECACA), width: 1),
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