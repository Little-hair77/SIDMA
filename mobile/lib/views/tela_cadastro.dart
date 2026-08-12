import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard.dart';

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

    final resultado = await _apiService.registrar(
      _nomeController.text.trim(),
      _emailController.text.trim(),
      _senhaController.text,
    );

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const TelaDashboard()),
      );
    } else {
      setState(() {
        _erro = resultado['mensagem'];
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: const Text('Criar conta'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) return 'Informe seu nome';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

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
                      if (valor == null || valor.length < 8) return 'Mínimo de 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _confirmarSenhaController,
                    obscureText: !_senhaVisivel,
                    decoration: InputDecoration(
                      labelText: 'Confirmar senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    validator: (valor) {
                      if (valor != _senhaController.text) return 'As senhas não coincidem';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_carregando)
                    const Center(child: CircularProgressIndicator())
                  else
                    ElevatedButton(
                      onPressed: _criarConta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Criar conta'),
                    ),

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