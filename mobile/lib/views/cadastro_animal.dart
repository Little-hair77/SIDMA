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

  final ImagePicker _picker = ImagePicker();
  Uint8List? _fotoAnimalBytes;

  String _sexoSelected = 'Fêmea'; // Padrão para rebanho bovino

  bool _carregando = false;
  String? _erro;

  bool get _editando => widget.animal != null;

  // Paleta de Cores
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86); 
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

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
              primary: corVerdeEscuro, 
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

      // Executa a chamada da API
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
      final XFile? arquivo = await _picker.pickImage(
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
        const SnackBar(content: Text('Erro ao selecionar imagem do animal.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  // Opções anexar ou tirar foto
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: corVerdeEscuro),
                title: const Text('Tirar Foto da Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined, color: corVerdeEscuro),
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
                    // Lógica adicional para remover foto da API pode ser necessária aqui no futuro
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  // Widget auxiliar para estilizar os inputs
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: corTextoPrimario, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: corVerdeEscuro.withOpacity(0.7)), // Ícone verde
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        floatingLabelStyle: const TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: corVerdeEscuro, width: 1.5), // Borda verde no foco
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      
      // - APP BAR VERDE ARREDONDADO 
      appBar: AppBar(
        backgroundColor: corVerdeEscuro,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _editando ? 'Editar Bovino' : 'Novo Cadastro',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
        ),
      ),
      
      body: Stack(
        children: [
          // MARCA D'ÁGUA 
          Center(
            child: Opacity(
              opacity: 0.04, 
              child: Image.asset(
                'assets/images/logoSIDMA-2.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 200, color: Colors.grey.shade400),
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          // - ÁREA DA FOTO DO ANIMAL 
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 24, bottom: 24),
                            child: Column(
                              children: [
                                GestureDetector(
                                  onTap: _mostrarOpcoesFoto,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: corVerdeEscuro.withOpacity(0.2), width: 4),
                                          boxShadow: [
                                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 65, 
                                          backgroundColor: corVerdeEscuro.withOpacity(0.05),
                                          backgroundImage: _fotoAnimalBytes != null 
                                              ? MemoryImage(_fotoAnimalBytes!) 
                                              : (widget.animal?['foto'] != null ? NetworkImage(widget.animal!['foto']) : null) as ImageProvider?,
                                          child: _fotoAnimalBytes == null && widget.animal?['foto'] == null
                                              ? const Icon(Icons.pets, size: 55, color: corVerdeEscuro)
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: corVerdePrincipal,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 3), 
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _fotoAnimalBytes == null && widget.animal?['foto'] == null ? 'Adicionar Foto do Animal' : 'Alterar Foto',
                                  style: const TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Toque no círculo acima para abrir a câmera.\nIsso facilita a identificação rápida no rebanho.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                                ),
                              ],
                            ),
                          ),

                          // - IDENTIFICAÇÃO 
                          _buildSeccionTitle('Identificação do Animal'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _brincoController,
                                    label: 'Número do Brinco *',
                                    hint: 'Ex: 1024A',
                                    prefixIcon: Icons.tag,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Insira o número do brinco' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _nomeController,
                                    label: 'Nome / Apelido (Opcional)',
                                    hint: 'Ex: Mimosa',
                                    prefixIcon: Icons.badge_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // - BIOMETRIA / CARACTERÍSTICAS
                          _buildSeccionTitle('Características Clínicas'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _racaController,
                                    label: 'Raça / Linhagem *',
                                    hint: 'Ex: Nelore, Gir, Guzerá',
                                    prefixIcon: Icons.category_outlined,
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Insira a raça' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Dropdown de Sexo
                                  DropdownButtonFormField<String>(
                                    value: _sexoSelected,
                                    style: const TextStyle(color: corTextoPrimario, fontSize: 15),
                                    decoration: InputDecoration(
                                      labelText: 'Sexo *',
                                      prefixIcon: Icon(Icons.transgender, color: corVerdeEscuro.withOpacity(0.7)),
                                      filled: true,
                                      fillColor: Colors.white,
                                      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      floatingLabelStyle: const TextStyle(color: corVerdeEscuro, fontWeight: FontWeight.bold),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: corVerdeEscuro, width: 1.5),
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
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _pesoController,
                                    label: 'Peso Estimado (kg) (Opcional)',
                                    hint: 'Ex: 450',
                                    keyboardType: TextInputType.number,
                                    prefixIcon: Icons.scale_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // - CRONOGRAMA E NOTAS
                          _buildSeccionTitle('Nascimento & Observações'),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: _selecionarData,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_today_outlined, color: corVerdeEscuro.withOpacity(0.7)),
                                              const SizedBox(width: 12),
                                              const Text('Data de Nascimento', style: TextStyle(fontSize: 14, color: corTextoPrimario)),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _dataNascimento != null ? corVerdeEscuro.withOpacity(0.1) : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _dataNascimento == null
                                                  ? 'Não Informada'
                                                  : "${_dataNascimento!.day.toString().padLeft(2, '0')}/${_dataNascimento!.month.toString().padLeft(2, '0')}/${_dataNascimento!.year}",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _dataNascimento != null ? corVerdeEscuro : Colors.grey[600],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _observacoesController,
                                    label: 'Observações Médicas / Histórico',
                                    hint: 'Ex: Animal em tratamento, restrições alimentares...',
                                    prefixIcon: Icons.description_outlined,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // - ÁREA DE NOTIFICAÇÃO DE ERRO 
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
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 22),
                                  const SizedBox(width: 12),
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

                          const SizedBox(height: 32),

                          // - BOTÃO DE SALVAMENTO 
                          if (_carregando)
                            const Center(child: CircularProgressIndicator(color: corVerdeEscuro))
                          else
                            ElevatedButton.icon(
                              onPressed: _salvar,
                              label: Text(
                                _editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR BOVINO',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: corVerdeEscuro,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 56),
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: corTextoPrimario,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}