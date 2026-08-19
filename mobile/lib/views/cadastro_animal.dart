import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../core/cores.dart'; 

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
              primary: AppColors.azulPrincipal,
              onPrimary: Colors.white,
              onSurface: AppColors.textoPrimario,
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
              fotoBytes: _fotoAnimalBytes, // <-- Adicionada a tag nomeada antes do valor
            )
          : await _apiService.cadastrarAnimal(
              _brincoController.text.trim(), 
              _nomeController.text.trim(), 
              _racaController.text.trim(), 
              dataFormatada,
              sexo: _sexoSelected,
              peso: _pesoController.text.trim(),
              observacoes: _observacoesController.text.trim(),
              fotoBytes: _fotoAnimalBytes, // <-- Adicionada a tag nomeada antes do valor
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao selecionar imagem do animal.')),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tirar Foto da Câmera'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_search_outlined),
                title: const Text('Escolher da Galeria'),
                onTap: () {
                  Navigator.pop(context);
                  _alterarFoto(ImageSource.gallery);
                },
              ),
              if (_fotoAnimalBytes != null)
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

  // Widget auxiliar para estilizar os inputs profissionais
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
      style: const TextStyle(color: AppColors.textoPrimario, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(prefixIcon, color: AppColors.azulPrincipal.withOpacity(0.7)),
        filled: true,
        fillColor: Colors.grey[50],
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        floatingLabelStyle: const TextStyle(color: AppColors.azulPrincipal, fontWeight: FontWeight.bold),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.azulPrincipal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar Bovino' : 'Novo Cadastro',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textoPrimario,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- SEÇÃO LOGO IDENTIDADE VISUAL ---
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Image.asset(
                      'assets/logoSIDMA-1.png', 
                      height: 65,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.pets,
                        size: 50,
                        color: AppColors.azulPrincipal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- IDENTIFICAÇÃO ---
                      _buildSeccionTitle('Identificação do Animal'),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
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
                      const SizedBox(height: 20),

                      // --- BIOMETRIA / CARACTERÍSTICAS ---
                      _buildSeccionTitle('Características Clínicas'),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _racaController,
                                label: 'Raça / Linhagem *',
                                hint: 'Ex: Nelore, Gir, Guzerá',
                                prefixIcon: Icons.category_outlined, // Teste de Icon
                                validator: (v) => v == null || v.trim().isEmpty ? 'Insira a raça' : null,
                              ),
                              const SizedBox(height: 16),
                              
                              // Dropdown de Sexo bem alinhado
                              DropdownButtonFormField<String>(
                                value: _sexoSelected,
                                decoration: InputDecoration(
                                  labelText: 'Sexo *',
                                  prefixIcon: Icon(Icons.transgender, color: AppColors.azulPrincipal.withOpacity(0.7)),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey.shade300),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: AppColors.azulPrincipal),
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
                      const SizedBox(height: 20),

                      // --- CRONOGRAMA E NOTAS ---
                      _buildSeccionTitle('Nascimento & Observações'),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey.shade200, width: 1),
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
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today_outlined, color: AppColors.azulPrincipal.withOpacity(0.7)),
                                          const SizedBox(width: 12),
                                          const Text('Data de Nascimento', style: TextStyle(fontSize: 14, color: AppColors.textoPrimario)),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _dataNascimento != null ? AppColors.azulPrincipal.withOpacity(0.1) : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _dataNascimento == null
                                              ? 'Não Informada'
                                              : "${_dataNascimento!.day}/${_dataNascimento!.month}/${_dataNascimento!.year}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _dataNascimento != null ? AppColors.azulPrincipal : Colors.grey[700],
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
                      
                      // --- ÁREA DE NOTIFICAÇÃO DE ERRO ---
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

                      // --- BOTÃO DE SALVAMENTO ---
                      if (_carregando)
                        const Center(child: CircularProgressIndicator(color: AppColors.azulPrincipal))
                      else
                        ElevatedButton(
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.verdePrincipal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            _editando ? 'SALVAR ALTERAÇÕES' : 'CADASTRAR BOVINO',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeccionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textoPrimario,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}