import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/cores.dart';
import '../navigation/nav.dart';
import 'login.dart';

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

  String? _perfilSelecionado;
  bool _aceitouTermos = false;
  bool _carregando = false;
  bool _senhaVisivel = false;
  String? _erro;

  // Lista de perfis profissionais do SIDMA
  final List<String> _perfis = [
    'Médico(a) Veterinário(a)',
    'Zootecnista',
    'Produtor(a) / Manejador(a)',
    'Estudante / Pesquisador(a)',
    'Outro',
  ];

  // Paleta de Cores
  Color get corVerdePrimaria => AppColors.of(context).primario;
  Color get corAzulMarinho => AppColors.of(context).destaque;
  Color get corTextoPrimario => AppColors.of(context).textoPrimario;
  Color get corTextoSecundario => AppColors.of(context).textoSecundario;
  Color get corCampoFundo => AppColors.of(context).superficieAlt;
  Color get corCardFundo => Theme.of(context).cardColor;
  Color get corFundoGeral => AppColors.of(context).fundo;

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

    if (!_aceitouTermos) {
      setState(() {
        _erro = 'Você precisa aceitar os Termos de Uso para prosseguir.';
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final resultado = await _apiService.registrar(
        _nomeController.text.trim(),
        _emailController.text.trim(),
        _senhaController.text,
        // Caso seu backend aceite perfil/cargo no registro, passe aqui:
        // perfil: _perfilSelecionado,
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
      hintText: rotulo,
      hintStyle: TextStyle(color: AppColors.of(context).textoDesabilitado, fontSize: 14),
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
        borderSide: BorderSide(color: corVerdePrimaria, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.of(context).erro, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.of(context).erro, width: 1.8),
      ),
    );
  }

  Widget _rotuloCampo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        texto,
        style: TextStyle(
          color: corTextoPrimario,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? corFundoGeral : corAzulMarinho,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // topo visual responsivo
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logoSIDMA-0.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Criar Conta',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? corTextoPrimario : Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Preencha as informações para ter acesso ao SIDMA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? corTextoSecundario : AppColors.of(context).textoDesabilitado,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Card expansível e responsivo
            SliverFillRemaining(
              hasScrollBody: false,
              child: Container(
                decoration: BoxDecoration(
                  color: corCardFundo,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Seleção de Abas
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: corCampoFundo,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).pushReplacement(
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) => const TelaLogin(),
                                            transitionDuration: Duration.zero,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        color: Colors.transparent,
                                        child: Text(
                                          'Entrar',
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
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: corVerdePrimaria,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Cadastrar',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo: Nome Completo
                            _rotuloCampo('Nome Completo *'),
                            TextFormField(
                              controller: _nomeController,
                              style: TextStyle(color: corTextoPrimario, fontSize: 14),
                              decoration: _estiloCampo(
                                rotulo: 'Ex: Dr. João Silva',
                                iconePrefixo: Icons.person_outline,
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) return 'Informe seu nome completo';
                                if (valor.trim().split(' ').length < 2) return 'Informe nome e sobrenome';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo: Perfil / Atuação Profissional
                            _rotuloCampo('Atuação Profissional *'),
                            DropdownButtonFormField<String>(
                              value: _perfilSelecionado,
                              icon: Icon(Icons.arrow_drop_down, color: corTextoSecundario),
                              style: TextStyle(color: corTextoPrimario, fontSize: 14),
                              dropdownColor: corCardFundo,
                              decoration: _estiloCampo(
                                rotulo: 'Selecione seu perfil',
                                iconePrefixo: Icons.work_outline,
                              ),
                              items: _perfis.map((String perfil) {
                                return DropdownMenuItem<String>(
                                  value: perfil,
                                  child: Text(perfil),
                                );
                              }).toList(),
                              onChanged: (valor) {
                                setState(() => _perfilSelecionado = valor);
                              },
                              validator: (valor) {
                                if (valor == null || valor.isEmpty) return 'Selecione sua atuação profissional';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo: E-mail
                            _rotuloCampo('E-mail *'),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(color: corTextoPrimario, fontSize: 14),
                              decoration: _estiloCampo(
                                rotulo: 'seuemail@exemplo.com',
                                iconePrefixo: Icons.email_outlined,
                              ),
                              validator: (valor) {
                                if (valor == null || valor.trim().isEmpty) return 'Informe seu e-mail';
                                if (!valor.contains('@')) return 'Formato de e-mail inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo: Senha
                            _rotuloCampo('Senha *'),
                            TextFormField(
                              controller: _senhaController,
                              obscureText: !_senhaVisivel,
                              style: TextStyle(color: corTextoPrimario, fontSize: 14),
                              decoration: _estiloCampo(
                                rotulo: 'Mínimo de 8 caracteres',
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
                                if (valor.length < 8) return 'A senha deve ter pelo menos 8 caracteres';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Campo: Confirmar Senha
                            _rotuloCampo('Confirmar Senha *'),
                            TextFormField(
                              controller: _confirmarSenhaController,
                              obscureText: !_senhaVisivel,
                              style: TextStyle(color: corTextoPrimario, fontSize: 14),
                              decoration: _estiloCampo(
                                rotulo: 'Repita a senha digitada',
                                iconePrefixo: Icons.lock_reset_outlined,
                              ),
                              validator: (valor) {
                                if (valor != _senhaController.text) return 'As senhas não coincidem';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Checkbox: Aceite de Termos de Uso
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: Checkbox(
                                    value: _aceitouTermos,
                                    activeColor: corVerdePrimaria,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _aceitouTermos = val ?? false;
                                        if (_aceitouTermos) _erro = null;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(color: corTextoSecundario, fontSize: 12.5),
                                      children: [
                                        const TextSpan(text: 'Li e concordo com os '),
                                        TextSpan(
                                          text: 'Termos de Serviço',
                                          style: TextStyle(
                                            color: corVerdePrimaria,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const TextSpan(text: ' e '),
                                        TextSpan(
                                          text: 'Privacidade',
                                          style: TextStyle(
                                            color: corVerdePrimaria,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Botão Cadastrar
                            if (_carregando)
                              Center(
                                child: CircularProgressIndicator(color: corVerdePrimaria),
                              )
                            else ...[
                              ElevatedButton(
                                onPressed: _criarConta,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: corVerdePrimaria,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'FINALIZAR CADASTRO',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Voltar ao Login
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Já tem uma conta? ',
                                    style: TextStyle(
                                      color: corTextoSecundario,
                                      fontSize: 13,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pushReplacement(
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) => const TelaLogin(),
                                          transitionDuration: Duration.zero,
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Entrar agora',
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

                            // Área de Erros
                            if (_erro != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.of(context).erroFundo,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.of(context).erro.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: AppColors.of(context).erro, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _erro!,
                                        style: TextStyle(color: AppColors.of(context).erro, fontSize: 12.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
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