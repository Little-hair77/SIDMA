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
  bool _lembrarMe = false;
  String? _erro;

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: kIsWeb ? _webClientId : null,
    serverClientId: kIsWeb ? null : _webClientId,
  );

  // Paleta de Cores Mantida
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
      hintText: rotulo,
      hintStyle: const TextStyle(color: corTextoSecundario, fontSize: 14),
      prefixIcon: Icon(iconePrefixo, color: corTextoSecundario, size: 20),
      suffixIcon: iconeSufixo,
      filled: true,
      fillColor: corCampoFundo,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        borderSide: const BorderSide(color: corVerdePrimaria, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tamanhoTela = MediaQuery.of(context).size;

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
        backgroundColor: corAzulMarinho,
        body: Stack(
          children: [
            // Fundo Superior (Área Escura)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: tamanhoTela.height * 0.40,
              child: Container(
                color: corAzulMarinho,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logoSIDMA-2.png',
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Bem-vindo de volta',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sistema Inteligente de Auxílio ao Diagnóstico de Mastite',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Card Principal do Formulário
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: tamanhoTela.height * 0.70,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Alternador de Aba (Entrar / Cadastrar)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: corCampoFundo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: corAzulMarinho,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Entrar',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const TelaCadastro(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        color: Colors.transparent,
                                        child: const Text(
                                          'Cadastrar',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: corTextoSecundario,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo de E-mail
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: corTextoPrimario, fontSize: 14),
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

                            // Campo de Senha
                            TextFormField(
                              controller: _senhaController,
                              obscureText: !_senhaVisivel,
                              style: const TextStyle(color: corTextoPrimario, fontSize: 14),
                              decoration: _estiloCampo(
                                rotulo: 'Senha',
                                iconePrefixo: Icons.lock_outline,
                                iconeSufixo: IconButton(
                                  icon: Icon(
                                    _senhaVisivel
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: corTextoSecundario,
                                    size: 20,
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
                            const SizedBox(height: 12),

                            // Lembrar-me e Esqueceu a Senha
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _lembrarMe,
                                        activeColor: corVerdePrimaria,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() => _lembrarMe = val ?? false);
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Manter conectado',
                                      style: TextStyle(
                                        color: corTextoSecundario,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const TelaRecuperarSenha(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Esqueceu a senha?',
                                    style: TextStyle(
                                      color: corVerdePrimaria,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Botão de Entrar
                            if (_carregando)
                              const Center(
                                child: CircularProgressIndicator(color: corVerdePrimaria),
                              )
                            else ...[
                              ElevatedButton(
                                onPressed: _entrarComEmailSenha,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: corVerdePrimaria,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Divisor
                              Row(
                                children: const [
                                  Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'OU CONTINUE COM',
                                      style: TextStyle(
                                        color: corTextoSecundario,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: corTextoPrimario,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 48),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  backgroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Rodapé Cadastro
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Novo por aqui? ',
                                    style: TextStyle(
                                      color: corTextoSecundario,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const TelaCadastro(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Crie uma conta',
                                      style: TextStyle(
                                        color: corVerdePrimaria,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // Exibição de Mensagens de Erro
                            if (_erro != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _erro!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 12,
                                        ),
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
          ],
        ),
      ),
    );
  }
}