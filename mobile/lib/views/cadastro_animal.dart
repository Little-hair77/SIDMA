import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TelaCadastroAnimal extends StatefulWidget {
  final dynamic animal; // null = criando novo; preenchido = editando

  const TelaCadastroAnimal({Key? key, this.animal}) : super(key: key);

  @override
  State<TelaCadastroAnimal> createState() => _TelaCadastroAnimalState();
}

class _TelaCadastroAnimalState extends State<TelaCadastroAnimal> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brincoController;
  late final TextEditingController _nomeController;
  late final TextEditingController _racaController;
  DateTime? _dataNascimento;

  bool _carregando = false;
  String? _erro;

  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  bool get _editando => widget.animal != null;

  @override
  void initState() {
    super.initState();
    _brincoController = TextEditingController(text: widget.animal?['brinco'] ?? '');
    _nomeController = TextEditingController(text: widget.animal?['nome'] ?? '');
    _racaController = TextEditingController(text: widget.animal?['raca'] ?? '');
    final dataStr = widget.animal?['data_nascimento'];
    if (dataStr != null) _dataNascimento = DateTime.tryParse(dataStr);
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    super.dispose();
  }

  InputDecoration _estiloCampo({required String rotulo, required IconData iconePrefixo}) {
    return InputDecoration(
      labelText: rotulo,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(iconePrefixo, color: corAzulPrincipal),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: corAzulPrincipal, width: 2),
      ),
    );
  }

  Future<void> _escolherData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data != null) setState(() => _dataNascimento = data);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final dataFormatada = _dataNascimento != null
        ? '${_dataNascimento!.year.toString().padLeft(4, '0')}-${_dataNascimento!.month.toString().padLeft(2, '0')}-${_dataNascimento!.day.toString().padLeft(2, '0')}'
        : null;

    final resultado = _editando
        ? await _apiService.atualizarAnimal(
            widget.animal['id'], _brincoController.text.trim(), _nomeController.text.trim(), _racaController.text.trim(), dataFormatada)
        : await _apiService.criarAnimal(
            _brincoController.text.trim(), _nomeController.text.trim(), _racaController.text.trim(), dataFormatada);

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _erro = resultado['mensagem'];
        _carregando = false;
      });
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir animal'),
        content: const Text('Tem certeza? As análises já feitas não serão apagadas, mas deixarão de estar vinculadas a esse animal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) {
      final sucesso = await _apiService.excluirAnimal(widget.animal['id']);
      if (sucesso && mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        iconTheme: const IconThemeData(color: corAzulPrincipal),
        title: Text(_editando ? 'Editar Animal' : 'Novo Animal', style: const TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold)),
        actions: [
          if (_editando) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: _excluir),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _brincoController,
                    style: const TextStyle(color: corTextoPrimario),
                    decoration: _estiloCampo(rotulo: 'Brinco / Identificação', iconePrefixo: Icons.tag),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe o brinco' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nomeController,
                    style: const TextStyle(color: corTextoPrimario),
                    decoration: _estiloCampo(rotulo: 'Nome (opcional)', iconePrefixo: Icons.pets),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _racaController,
                    style: const TextStyle(color: corTextoPrimario),
                    decoration: _estiloCampo(rotulo: 'Raça (opcional)', iconePrefixo: Icons.category_outlined),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _escolherData,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _estiloCampo(rotulo: 'Data de nascimento (opcional)', iconePrefixo: Icons.calendar_today_outlined),
                      child: Text(
                        _dataNascimento != null
                            ? '${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}'
                            : 'Toque para escolher',
                        style: const TextStyle(color: corTextoPrimario),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_carregando)
                    const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
                  else
                    ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corVerdePrincipal,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR ANIMAL', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    ),
                  if (_erro != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                      child: Text(_erro!, style: const TextStyle(color: Colors.redAccent), textAlign: TextAlign.center),
                    ),
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