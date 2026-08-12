import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';
import 'dashboard.dart';
import 'tela_cadastro.dart';

// Client ID do tipo "Aplicativo da Web", criado no Google Cloud Console.
// É o mesmo valor configurado em GOOGLE_CLIENT_ID no settings.py do Django.
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

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _irParaDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TelaDashboard()),
    );
  }

  Future<void> _entrarComEmailSenha() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

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
          _erro = 'Não foi possível obter o token do Google. Tente novamente ou use e-mail/senha.';
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
          _erro = 'Falha ao autenticar no servidor. Tente novamente.';
          _carregando = false;
        });
      }
    } catch (e) {
      setState(() {
        _erro = 'Erro ao fazer login: $e';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_hospital, size: 72, color: Colors.teal),
                  const SizedBox(height: 12),
                  const Text(
                    'SIDMA',
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  const Text(
                    'Sistema Inteligente de Auxílio ao Diagnóstico de Mastite',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 36),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail';
                      if (!valor.contains('@')) return 'E-mail inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) return 'Informe sua senha';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  if (_carregando)
                    const CircularProgressIndicator()
                  else ...[
                    ElevatedButton(
                      onPressed: _entrarComEmailSenha,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Entrar'),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TelaCadastro()),
                        );
                      },
                      child: const Text('Não tem conta? Criar conta'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('ou', style: TextStyle(color: Colors.grey)),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _entrarComGoogle,
                      icon: const Icon(Icons.login),
                      label: const Text('Entrar com Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],

                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Text(_erro!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}