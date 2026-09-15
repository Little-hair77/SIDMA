import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../navigation/nav.dart';
import 'cadastro.dart';
import 'recuperar_senha.dart';

const String _webClientId =
    '286956469225-sc8ji78jvpllpr7qjfiu7sv8ak0i0e3h.apps.googleusercontent.com';

class TelaLogin extends StatefulWidget {
  const TelaLogin({Key? key}) : super(key: key);

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  // Paleta de Cores
  static const Color corVerdePrimaria = Color(0xFF10B981); 
  static const Color corAzulMarinho   = Color(0xFF1E293B); 
  static const Color corTextoPrimario = Color(0xFF0F172A); 
  static const Color corTextoSecundario = Color(0xFF64748B); 
  static const Color corCampoFundo    = Color(0xFFF1F5F9); 
  static const Color corFundo         = Color(0xFFF8FAFC); 

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _irParaDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelaPrincipal()),
    );
  }

  Future<void> _entrarComEmailSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _apiService.fazerLogin(
        _emailController.text.trim(),
        _senhaController.text,
      );

      if (!mounted) return;

      if (resultado['sucesso'] == true) {
        _irParaDashboard();
      } else {
        setState(() {
          _erro = resultado['mensagem'];
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Ocorreu um erro inesperado. Tente novamente.';
        _carregando = false;
      });
    }
  }

  Future<void> _entrarComGoogle() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final GoogleSignInAccount? contaGoogle = await _googleSignIn.signIn();
      if (contaGoogle == null) {
        setState(() => _carregando = false);
        return;
      }

      final GoogleSignInAuthentication authGoogle = await contaGoogle.authentication;
      final String? idToken = authGoogle.idToken;

      if (idToken == null) {
        setState(() {
          _erro = 'Não foi possível obter a autenticação do Google.';
          _carregando = false;
        });
        return;
      }

      final sucesso = await _apiService.fazerLoginGoogle(idToken);

      if (!mounted) return;

      if (sucesso) {
        _irParaDashboard();
      } else {
        setState(() {
          _erro = 'Falha ao sincronizar conta Google com o servidor.';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro na conexão com o Google: $e';
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
                          if (valor.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                          return null;
                        },
                      ),
                      
                      // Esqueceu a senha?
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const TelaRecuperarSenha()),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: corAzulMarinho,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          ),
                          child: const Text(
                            'Esqueceu a senha?', 
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // - BOTÕES DE AÇÃO 
                      if (_carregando)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: corVerdePrimaria),
                        )
                      else ...[
                        // Botão Entrar Principal 
                        ElevatedButton(
                          onPressed: _entrarComEmailSenha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrimaria, 
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54), 
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'ENTRAR',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Divisor "ou"
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Text('ou acesse com', style: TextStyle(color: corTextoSecundario, fontSize: 12)),
                            ),
                            Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Botão Google
                        OutlinedButton.icon(
                          onPressed: _entrarComGoogle,
                          icon: Image.asset(
                            'assets/images/logoGoogle.png',
                            height: 18,
                            fit: BoxFit.contain,
                          ),
                          label: const Text(
                            'Continuar com Google',
                            style: TextStyle(fontSize: 15, color: corTextoPrimario, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 54),
                            side: const BorderSide(color: Color(0xFFCBD5E1)), 
                            backgroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Criar Conta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Novo por aqui?', style: TextStyle(color: corTextoSecundario, fontSize: 14)),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TelaCadastro()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: corAzulMarinho,
                                padding: const EdgeInsets.only(left: 6),
                              ),
                              child: const Text(
                                'Crie sua conta',
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