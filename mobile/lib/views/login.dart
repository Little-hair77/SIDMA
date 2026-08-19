import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import '../navigation/nav.dart';
import 'cadastro.dart';

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

  // DEFINIÇÃO DA PALETA DE CORES VÍVIDAS BASEADA NA LOGO
  static const Color corAzulPrincipal = Color(0xFF0D6EFD); 
  static const Color corVerdePrincipal = Color(0xFF74C319); 
  static const Color corTextoPrimario = Color(0xFF1E293B); 
  static const Color corFundo = Colors.white; 

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

  // Helper para criar o estilo dos campos de texto (evita repetição)
  InputDecoration _estiloCampo({required String rotulo, required IconData iconePrefixo, Widget? iconeSufixo}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(iconePrefixo, color: corAzulPrincipal),
      suffixIcon: iconeSufixo,
      filled: true,
      fillColor: Colors.grey[100], 
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16), // Aumenta a área de toque
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, // Remove a borda padrão
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
    // Definindo um ThemeData local para garantir o estilo Material 3 e cores corretas
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corAzulPrincipal,
          primary: corAzulPrincipal,
          secondary: corVerdePrincipal,
          background: corFundo,
        ),
        // Se usar Google Fonts, descomente abaixo:
        // textTheme: GoogleFonts.robotoTextTheme(Theme.of(context).textTheme),
      ),
      child: Scaffold(
        backgroundColor: corFundo,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420), // Um pouco mais largo para tablets/web
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // --- CABEÇALHO ---
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
                      const SizedBox(height: 48), 

                      // --- CAMPOS DE ENTRADA ---
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
                      const SizedBox(height: 18), // Espaçamento consistente

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
                          if (valor.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                          return null;
                        },
                      ),
                      
                      // Esqueceu a senha? (Adicionado para profissionalismo)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Lógica de recuperação de senha
                          },
                          style: TextButton.styleFrom(foregroundColor: corAzulPrincipal),
                          child: const Text('Esqueceu a senha?', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- BOTÕES DE AÇÃO ---
                      if (_carregando)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        )
                      else ...[
                        // Botão Entrar Principal 
                        ElevatedButton(
                          onPressed: _entrarComEmailSenha,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrincipal, 
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56), 
                            elevation: 2, // Sombra sutil M3
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Mais arredondado
                          ),
                          child: const Text(
                            'ENTRAR',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Divisor "ou"
                        Row(
                          children: const [
                            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text('ou acesse com', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Botão Google Profissional
                        OutlinedButton.icon(
                          onPressed: _entrarComGoogle,
                          icon: Image.asset('assets/images/logoGoogle.png',
                          height: 18,
                          fit: BoxFit.contain,),
                          label: const Text(
                            'Continuar com Google',
                            style: TextStyle(fontSize: 16, color: corTextoPrimario, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            side: BorderSide(color: Colors.grey[300]!), 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Criar Conta
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Novo por aqui?', style: TextStyle(color: Colors.black54)),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const TelaCadastro()),
                                );
                              },
                              style: TextButton.styleFrom(foregroundColor: corAzulPrincipal),
                              child: const Text(
                                'Crie sua conta',
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