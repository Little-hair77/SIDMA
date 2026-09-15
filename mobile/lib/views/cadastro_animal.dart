import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  late final TextEditingController _pesoController;
  late final TextEditingController _observacoesController;

  DateTime? _dataNascimento;
  Uint8List? _fotoAnimalBytes;

  String _sexoSelected = 'Fêmea';

  bool _carregando = false;
  String? _erro;

  bool get _editando => widget.animal != null;

  // Paleta de Cores 
  static const Color corAppBar = Color(0xFF1E2A38);
  static const Color corVerdePrincipal = Color(0xFF00B67A);
  static const Color corVerdeSuave = Color(0xFFE6F4EA);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF0F172A);
  static const Color corTextoSecundario = Color(0xFF64748B);
  static const Color corBordaInput = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _brincoController = TextEditingController(text: widget.animal?['brinco'] ?? '');
    _nomeController = TextEditingController(text: widget.animal?['nome'] ?? '');
    _racaController = TextEditingController(text: widget.animal?['raca'] ?? '');
    _pesoController = TextEditingController(text: widget.animal?['peso']?.toString() ?? '');
    _observacoesController = TextEditingController(text: widget.animal?['observacoes'] ?? '');

    _sexoSelected = widget.animal?['sexo'] ?? 'Fêmea';
    if (widget.animal?['data_nascimento'] != null) {
      _dataNascimento = DateTime.tryParse(widget.animal!['data_nascimento']);
    }
  }

  @override
  void dispose() {
    _brincoController.dispose();
    _nomeController.dispose();
    _racaController.dispose();
    _pesoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimento ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: corVerdePrincipal,
              onPrimary: Colors.white,
              onSurface: corTextoPrimario,
            ),
          ),
          child: child!,
        );
      },
    );
    if (escolhida != null) {
      setState(() => _dataNascimento = escolhida);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dataFormatada = _dataNascimento != null
          ? '${_dataNascimento!.year.toString().padLeft(4, '0')}-${_dataNascimento!.month.toString().padLeft(2, '0')}-${_dataNascimento!.day.toString().padLeft(2, '0')}'
          : null;

      final resultado = _editando
          ? await _apiService.atualizarAnimal(
              widget.animal['id'],
              _brincoController.text.trim(),
              _nomeController.text.trim(),
              _racaController.text.trim(),
              dataFormatada,
              sexo: _sexoSelected,
              peso: _pesoController.text.trim(),
              observacoes: _observacoesController.text.trim(),
              fotoBytes: _fotoAnimalBytes,
            )
          : await _apiService.cadastrarAnimal(
              _brincoController.text.trim(),
              _nomeController.text.trim(),
              _racaController.text.trim(),
              dataFormatada,
              sexo: _sexoSelected,
              peso: _pesoController.text.trim(),
              observacoes: _observacoesController.text.trim(),
              fotoBytes: _fotoAnimalBytes,
            );

      if (!mounted) return;

      if (resultado['sucesso'] == true) {
        setState(() => _carregando = false);
        Navigator.of(context).pop();
      } else {
        setState(() {
          _erro = resultado['mensagem'] ?? 'Erro ao processar dados do animal.';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro interno no aplicativo: $e';
        _carregando = false;
      });
    }
  }

  Future<void> _alterarFoto(ImageSource fonte) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? arquivo = await picker.pickImage(
        source: fonte,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (arquivo != null) {
        final bytes = await arquivo.readAsBytes();
        setState(() {
          _fotoAnimalBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao selecionar imagem do animal.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Foto do Animal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: corTextoPrimario,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: corVerdePrincipal),
                title: const Text('Tirar Foto da Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: corVerdePrincipal),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoAnimalBytes != null || (widget.animal?['foto'] != null))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover Foto', style: TextStyle(color: Colors.redAccent)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _fotoAnimalBytes = null);
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Campo de texto limpo e direto, sem caixas desnecessárias no ícone
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: corTextoPrimario, fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: corTextoSecundario, size: 22),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 14),
        floatingLabelStyle: const TextStyle(color: corVerdePrincipal, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: corBordaInput, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: corVerdePrincipal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }

  // Títulos de Seção discretos e organizados
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: corVerdePrincipal),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: corTextoSecundario,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: corAppBar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _editando ? 'Editar Bovino' : 'Novo Cadastro',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar / Seleção de Foto
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _mostrarOpcoesFoto,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: corVerdeSuave,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: CircleAvatar(
                                radius: 52,
                                backgroundColor: corVerdeSuave,
                                backgroundImage: _fotoAnimalBytes != null
                                    ? MemoryImage(_fotoAnimalBytes!)
                                    : (widget.animal?['foto'] != null
                                        ? NetworkImage(widget.animal!['foto'])
                                        : null) as ImageProvider?,
                                child: _fotoAnimalBytes == null && widget.animal?['foto'] == null
                                    ? const Icon(Icons.pets, size: 48, color: corVerdePrincipal)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: corVerdePrincipal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2.5),
                                ),
                                padding: const EdgeInsets.all(7),
                                child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _mostrarOpcoesFoto,
                        child: Text(
                          _fotoAnimalBytes == null && widget.animal?['foto'] == null
                              ? 'Adicionar Foto'
                              : 'Alterar Foto',
                          style: const TextStyle(
                            color: corVerdePrincipal,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // SEÇÃO 1: IDENTIFICAÇÃO
                _buildSectionHeader('IDENTIFICAÇÃO', Icons.badge_outlined),
                _buildTextField(
                  controller: _brincoController,
                  label: 'Número do Brinco *',
                  hint: 'Ex: 1024A',
                  prefixIcon: Icons.tag,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Insira o número do brinco' : null,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nomeController,
                  label: 'Nome / Apelido (Opcional)',
                  hint: 'Ex: Mimosa',
                  prefixIcon: Icons.edit_note,
                ),

                const SizedBox(height: 20),

                // SEÇÃO 2: CARACTERÍSTICAS
                _buildSectionHeader('CARACTERÍSTICAS', Icons.tune),
                _buildTextField(
                  controller: _racaController,
                  label: 'Raça / Linhagem *',
                  hint: 'Ex: Nelore, Gir, Guzerá',
                  prefixIcon: Icons.category_outlined,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Insira a raça' : null,
                ),
                const SizedBox(height: 12),
                
                // Dropdown limpo no mesmo formato dos inputs
                DropdownButtonFormField<String>(
                  value: _sexoSelected,
                  style: const TextStyle(color: corTextoPrimario, fontSize: 15, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Sexo *',
                    prefixIcon: const Icon(Icons.transgender, color: corTextoSecundario, size: 22),
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 14),
                    floatingLabelStyle: const TextStyle(color: corVerdePrincipal, fontWeight: FontWeight.bold),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: corBordaInput, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: corVerdePrincipal, width: 1.5),
                    ),
                  ),
                  items: ['Fêmea', 'Macho'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (novo) {
                    if (novo != null) setState(() => _sexoSelected = novo);
                  },
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _pesoController,
                  label: 'Peso Estimado (kg)',
                  hint: 'Ex: 450',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.scale_outlined,
                ),

                const SizedBox(height: 20),

                // SEÇÃO 3: OUTRAS INFORMAÇÕES
                _buildSectionHeader('OUTRAS INFORMAÇÕES', Icons.info_outline),
                
                // Seletor de Data Clean
                InkWell(
                  onTap: _selecionarData,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: corBordaInput),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: corTextoSecundario, size: 20),
                        const SizedBox(width: 12),
                        const Text('Data de Nascimento', style: TextStyle(fontSize: 14, color: corTextoSecundario)),
                        const Spacer(),
                        Text(
                          _dataNascimento == null
                              ? 'Não informada'
                              : "${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _dataNascimento != null ? corVerdePrincipal : corTextoSecundario,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _observacoesController,
                  label: 'Observações / Histórico',
                  hint: 'Ex: Histórico de vacinas, medicação...',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 2,
                ),

                if (_erro != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _erro!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Botão de Salvar
                if (_carregando)
                  const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
                else
                  ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corVerdePrincipal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}