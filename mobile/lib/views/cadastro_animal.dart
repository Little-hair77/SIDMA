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
  DateTime? _dataUltimoCio;
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
    if (widget.animal?['data_ultimo_cio'] != null) {
      _dataUltimoCio = DateTime.tryParse(widget.animal!['data_ultimo_cio']);
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

  Future<void> _selecionarDataUltimoCio() async {
    final escolhida = await showDatePicker(
      context: context,
      initialDate: _dataUltimoCio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Data do último cio observado',
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
      setState(() => _dataUltimoCio = escolhida);
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
      // Se o usuário trocar o sexo para "Macho"
      // depois de já ter registrado uma data, o campo deixa de ser enviado.
      final dataCioFormatada = (_sexoSelected == 'Fêmea' && _dataUltimoCio != null)
          ? '${_dataUltimoCio!.year.toString().padLeft(4, '0')}-${_dataUltimoCio!.month.toString().padLeft(2, '0')}-${_dataUltimoCio!.day.toString().padLeft(2, '0')}'
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
              dataUltimoCio: dataCioFormatada,
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
              dataUltimoCio: dataCioFormatada,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: corTextoPrimario,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: corVerdePrincipal),
                title: const Text('Tirar foto com a câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: corVerdePrincipal),
                title: const Text('Escolher da galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoAnimalBytes != null || (widget.animal?['foto'] != null))
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Remover foto', style: TextStyle(color: Colors.redAccent)),
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

  Widget _buildCardSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: corBordaInput, width: 0.8),
      ),
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

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
      style: const TextStyle(color: corTextoPrimario, fontSize: 14, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: corTextoSecundario.withOpacity(0.6), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: corTextoSecundario, size: 20),
        filled: true,
        fillColor: corFundo,
        labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 13),
        floatingLabelStyle: const TextStyle(color: corVerdePrincipal, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: corBordaInput.withOpacity(0.8), width: 1),
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

  Widget _buildSectionHeader(String title, IconData icon, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: corVerdePrincipal),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: corTextoSecundario,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: corTextoSecundario.withOpacity(0.8),
              ),
            ),
          ],
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
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topo: Photo Picker 
                Center(
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _mostrarOpcoesFoto,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: corVerdeSuave,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipOval(
                                child: _fotoAnimalBytes != null
                                    ? Image.memory(_fotoAnimalBytes!, fit: BoxFit.cover)
                                    : (widget.animal?['foto'] != null
                                        ? Image.network(widget.animal!['foto'], fit: BoxFit.cover)
                                        : const Icon(Icons.pets, size: 42, color: corVerdePrincipal)),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _mostrarOpcoesFoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: corVerdePrincipal,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Toque para adicionar ou alterar a foto',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: corTextoSecundario,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Formatos aceitos: JPG ou PNG (opcional)',
                        style: TextStyle(
                          fontSize: 11,
                          color: corTextoSecundario.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CARD 1: IDENTIFICAÇÃO
                _buildCardSection(
                  children: [
                    _buildSectionHeader(
                      'IDENTIFICAÇÃO',
                      Icons.badge_outlined,
                      subtitle: 'Insira os dados principais de registro do animal no sistema.',
                    ),
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
                  ],
                ),

                // CARD 2: CARACTERÍSTICAS
                _buildCardSection(
                  children: [
                    _buildSectionHeader(
                      'CARACTERÍSTICAS',
                      Icons.tune,
                      subtitle: 'Informe as especificações físicas e raciais para controle de rebanho.',
                    ),
                    _buildTextField(
                      controller: _racaController,
                      label: 'Raça / Linhagem *',
                      hint: 'Ex: Nelore, Gir, Guzerá',
                      prefixIcon: Icons.category_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Insira a raça' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _sexoSelected,
                      style: const TextStyle(color: corTextoPrimario, fontSize: 14, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Sexo *',
                        prefixIcon: const Icon(Icons.transgender, color: corTextoSecundario, size: 20),
                        filled: true,
                        fillColor: corFundo,
                        labelStyle: const TextStyle(color: corTextoSecundario, fontSize: 13),
                        floatingLabelStyle: const TextStyle(color: corVerdePrincipal, fontWeight: FontWeight.bold),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: corBordaInput.withOpacity(0.8), width: 1),
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
                  ],
                ),

                // CARD 3: OUTRAS INFORMAÇÕES
                _buildCardSection(
                  children: [
                    _buildSectionHeader(
                      'OUTRAS INFORMAÇÕES',
                      Icons.info_outline,
                      subtitle: 'Registre datas importantes e detalhes adicionais de acompanhamento.',
                    ),
                    InkWell(
                      onTap: _selecionarData,
                      borderRadius: BorderRadius.circular(12),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: corFundo,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: corBordaInput.withOpacity(0.8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, color: corTextoSecundario, size: 18),
                            const SizedBox(width: 12),
                            const Text('Data de Nascimento', style: TextStyle(fontSize: 13, color: corTextoSecundario)),
                            const Spacer(),
                            Text(
                              _dataNascimento == null
                                  ? 'Não informada'
                                  : "${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _dataNascimento != null ? corVerdePrincipal : corTextoSecundario,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_sexoSelected == 'Fêmea') ...[
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _selecionarDataUltimoCio,
                        borderRadius: BorderRadius.circular(12),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: corFundo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: corBordaInput.withOpacity(0.8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.favorite_outline, color: corTextoSecundario, size: 18),
                              const SizedBox(width: 12),
                              const Text('Data do Último Cio', style: TextStyle(fontSize: 13, color: corTextoSecundario)),
                              const Spacer(),
                              Text(
                                _dataUltimoCio == null
                                    ? 'Não informada'
                                    : "${_dataUltimoCio!.day.toString().padLeft(2, '0')}/${_dataUltimoCio!.month.toString().padLeft(2, '0')}/${_dataUltimoCio!.year}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _dataUltimoCio != null ? corVerdePrincipal : corTextoSecundario,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Usada para prever o próximo cio (~21 dias depois) e gerar um alerta de atenção reprodutiva.',
                          style: TextStyle(fontSize: 11, color: corTextoSecundario),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _observacoesController,
                      label: 'Observações / Histórico',
                      hint: 'Ex: Histórico de vacinas, medicação...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),

                if (_erro != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.shade100, width: 0.8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
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

                // Botão principal de ação
                if (_carregando)
                  const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
                else
                  ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text(
                      _editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corVerdePrincipal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}