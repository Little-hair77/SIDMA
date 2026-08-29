import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Tela de recuperação de senha do SIDMA.
///
/// Fluxo em duas etapas, na mesma tela:
///   1) usuário informa o e-mail -> backend gera e "envia" um código de 6 dígitos
///      (endpoint: POST auth/recuperar-senha/solicitar/)
///   2) usuário informa o código recebido + a nova senha
///      (endpoint: POST auth/recuperar-senha/confirmar/)
///
/// Uso (a partir da tela de login, por exemplo):
///   Navigator.of(context).push(
///     MaterialPageRoute(builder: (_) => const TelaRecuperarSenha()),
///   );
class TelaRecuperarSenha extends StatefulWidget {
  const TelaRecuperarSenha({Key? key}) : super(key: key);

  @override
  State<TelaRecuperarSenha> createState() => _TelaRecuperarSenhaState();
}

class _TelaRecuperarSenhaState extends State<TelaRecuperarSenha> {
  final ApiService _apiService = ApiService();

  // Paleta de Cores (mesma paleta usada em login.dart)
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corTextoPrimario = Color(0xFF1E293B);
  static const Color corFundo = Colors.white;

  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyCodigo = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  int _etapa = 1; // 1 = solicitar código, 2 = confirmar código + nova senha
  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;
  String? _sucesso;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    if (!_formKeyEmail.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _apiService.solicitarRecuperacaoSenha(_emailController.text.trim());

    if (!mounted) return;

    setState(() {
      _carregando = false;
      if (resultado['sucesso'] == true) {
        _etapa = 2;
        _sucesso = resultado['mensagem'];
      } else {
        _erro = resultado['mensagem'] ?? 'Não foi possível enviar o código. Tente novamente.';
      }
    });
  }

  Future<void> _confirmarNovaSenha() async {
    if (!_formKeyCodigo.currentState!.validate()) return;

    if (_novaSenhaController.text != _confirmarSenhaController.text) {
      setState(() => _erro = 'As senhas não coincidem.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _apiService.confirmarRecuperacaoSenha(
      _emailController.text.trim(),
      _codigoController.text.trim(),
      _novaSenhaController.text,
    );

    if (!mounted) return;

    setState(() => _carregando = false);

    if (resultado['sucesso'] == true) {
      _mostrarSucessoEVoltar();
    } else {
      setState(() => _erro = resultado['mensagem'] ?? 'Código inválido ou expirado.');
    }
  }

  void _mostrarSucessoEVoltar() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: corVerdePrincipal),
            SizedBox(width: 8),
            Text('Senha redefinida'),
          ],
        ),
        content: const Text('Sua senha foi alterada com sucesso. Faça login novamente com a nova senha.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // fecha o diálogo
              Navigator.of(context).pop(); // volta para a tela de login
            },
            child: const Text('Ir para o login'),
          ),
        ],
      ),
    );
  }

  InputDecoration _estiloCampo({required String rotulo, required IconData iconePrefixo, Widget? iconeSufixo}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(iconePrefixo, color: corAzulPrincipal),
      suffixIcon: iconeSufixo,
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corFundo,
        elevation: 0,
        iconTheme: const IconThemeData(color: corTextoPrimario),
        title: const Text('Recuperar senha', style: TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _etapa == 1 ? _construirEtapaEmail() : _construirEtapaCodigo(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _construirEtapaEmail() {
    return Form(
      key: _formKeyEmail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.lock_reset, size: 64, color: corAzulPrincipal),
          const SizedBox(height: 16),
          const Text(
            'Informe o e-mail da sua conta. Enviaremos um código de verificação válido por 15 minutos.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: corTextoPrimario),
            decoration: _estiloCampo(rotulo: 'E-mail', iconePrefixo: Icons.email_outlined),
            validator: (valor) {
              if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail';
              if (!valor.contains('@')) return 'Formato de e-mail inválido';
              return null;
            },
          ),
          const SizedBox(height: 24),
          _construirMensagens(),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ElevatedButton(
              onPressed: _solicitarCodigo,
              style: ElevatedButton.styleFrom(
                backgroundColor: corVerdePrincipal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ENVIAR CÓDIGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
        ],
      ),
    );
  }

  Widget _construirEtapaCodigo() {
    return Form(
      key: _formKeyCodigo,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 64, color: corAzulPrincipal),
          const SizedBox(height: 16),
          Text(
            'Enviamos um código para ${_emailController.text.trim()}. Informe-o abaixo junto com a nova senha.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _codigoController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: const TextStyle(color: corTextoPrimario, fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: _estiloCampo(rotulo: 'Código de 6 dígitos', iconePrefixo: Icons.pin_outlined).copyWith(counterText: ''),
            validator: (valor) {
              if (valor == null || valor.trim().length != 6) return 'Informe o código de 6 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _novaSenhaController,
            obscureText: !_senhaVisivel,
            style: const TextStyle(color: corTextoPrimario),
            decoration: _estiloCampo(
              rotulo: 'Nova senha',
              iconePrefixo: Icons.lock_outline,
              iconeSufixo: IconButton(
                icon: Icon(_senhaVisivel ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey),
                onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
              ),
            ),
            validator: (valor) {
              if (valor == null || valor.isEmpty) return 'Informe a nova senha';
              if (valor.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _confirmarSenhaController,
            obscureText: !_senhaVisivel,
            style: const TextStyle(color: corTextoPrimario),
            decoration: _estiloCampo(rotulo: 'Confirmar nova senha', iconePrefixo: Icons.lock_outline),
            validator: (valor) {
              if (valor == null || valor.isEmpty) return 'Confirme a nova senha';
              return null;
            },
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _carregando ? null : _solicitarCodigo,
              style: TextButton.styleFrom(foregroundColor: corAzulPrincipal),
              child: const Text('Reenviar código', style: TextStyle(fontSize: 13)),
            ),
          ),
          _construirMensagens(),
          if (_carregando)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ElevatedButton(
              onPressed: _confirmarNovaSenha,
              style: ElevatedButton.styleFrom(
                backgroundColor: corVerdePrincipal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('REDEFINIR SENHA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
        ],
      ),
    );
  }

  Widget _construirMensagens() {
    if (_erro == null && _sucesso == null) return const SizedBox.shrink();
    final bool ehErro = _erro != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: ehErro ? Colors.red[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ehErro ? Colors.redAccent : corVerdePrincipal, width: 0.5),
        ),
        child: Row(
          children: [
            Icon(ehErro ? Icons.error_outline : Icons.check_circle_outline, color: ehErro ? Colors.redAccent : corVerdePrincipal, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ehErro ? _erro! : _sucesso!,
                style: TextStyle(color: ehErro ? Colors.redAccent : Colors.green[800], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}