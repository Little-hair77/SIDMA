import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TelaRegistrarTratamento extends StatefulWidget {
  final int animalId;
  final String nomeAnimal;

  const TelaRegistrarTratamento({
    Key? key,
    required this.animalId,
    required this.nomeAnimal,
  }) : super(key: key);

  @override
  State<TelaRegistrarTratamento> createState() => _TelaRegistrarTratamentoState();
}

class _TelaRegistrarTratamentoState extends State<TelaRegistrarTratamento> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _medicamentoController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Paleta de Cores 
  static const Color corAppBar = Color(0xFF1E2A38);
  static const Color corVerdePrincipal = Color(0xFF00B67A);
  static const Color corVerdeSuave = Color(0xFFE6F4EA);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF0F172A);
  static const Color corTextoSecundario = Color(0xFF64748B);
  static const Color corBordaInput = Color(0xFFE2E8F0);

  DateTime _dataInicio = DateTime.now();
  DateTime? _dataFimCarencia;
  bool _carregando = false;
  List<dynamic> _historico = [];
  bool _carregandoHistorico = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  @override
  void dispose() {
    _medicamentoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregarHistorico() async {
    final lista = await _apiService.listarTratamentos(widget.animalId);
    if (!mounted) return;
    setState(() {
      _historico = lista ?? [];
      _carregandoHistorico = false;
    });
  }

  String _formatarData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  
  String _paraApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatarDataTexto(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return _formatarData(d);
  }

  Future<void> _escolherDataInicio() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataInicio,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
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
    if (data != null) setState(() => _dataInicio = data);
  }

  Future<void> _escolherDataFimCarencia() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFimCarencia ?? _dataInicio.add(const Duration(days: 3)),
      firstDate: _dataInicio,
      lastDate: DateTime(2100),
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
    if (data != null) setState(() => _dataFimCarencia = data);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataFimCarencia == null) {
      setState(() => _erro = 'Informe a data de fim da carência do leite.');
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final resultado = await _apiService.registrarTratamento(
      widget.animalId,
      _medicamentoController.text.trim(),
      _paraApi(_dataInicio),
      _paraApi(_dataFimCarencia!),
      _observacoesController.text.trim(),
    );

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      _medicamentoController.clear();
      _observacoesController.clear();
      setState(() {
        _dataFimCarencia = null;
        _carregando = false;
      });
      await _carregarHistorico();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tratamento registrado com sucesso!'),
          backgroundColor: corVerdePrincipal,
        ),
      );
    } else {
      setState(() {
        _erro = resultado['mensagem'] ?? 'Erro ao registrar tratamento.';
        _carregando = false;
      });
    }
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
          'Tratamento — ${widget.nomeAnimal}',
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
                // Card de Alerta Sanitário
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Enquanto estiver em período de carência, o leite deste animal não deve ser descartado no tanque comum.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber.shade900,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // CARD 1: DADOS DO TRATAMENTO
                _buildCardSection(
                  children: [
                    _buildSectionHeader(
                      'NOVO TRATAMENTO',
                      Icons.medication_outlined,
                      subtitle: 'Informe o medicamento aplicado e os prazos de carência.',
                    ),
                    _buildTextField(
                      controller: _medicamentoController,
                      label: 'Medicamento / Vacina',
                      hint: 'Ex: Ivermectina, Antibiótico X',
                      prefixIcon: Icons.science_outlined,
                    ),
                    const SizedBox(height: 12),
                    
                    // Seletor: Data de Início
                    InkWell(
                      onTap: _escolherDataInicio,
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
                            const Text('Início do Tratamento', style: TextStyle(fontSize: 13, color: corTextoSecundario)),
                            const Spacer(),
                            Text(
                              _formatarData(_dataInicio),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: corVerdePrincipal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Seletor: Fim da Carência
                    InkWell(
                      onTap: _escolherDataFimCarencia,
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
                            const Icon(Icons.event_busy_outlined, color: corTextoSecundario, size: 18),
                            const SizedBox(width: 12),
                            const Text('Fim da Carência *', style: TextStyle(fontSize: 13, color: corTextoSecundario)),
                            const Spacer(),
                            Text(
                              _dataFimCarencia != null ? _formatarData(_dataFimCarencia!) : 'Selecionar data',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _dataFimCarencia != null ? corVerdePrincipal : Colors.redAccent,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _observacoesController,
                      label: 'Observações / Dosagem',
                      hint: 'Ex: Aplicado 5ml via subcutânea...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 2,
                    ),
                  ],
                ),

                // Mensagem de Erro
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

                // Botão Registrar
                if (_carregando)
                  const Center(child: CircularProgressIndicator(color: corVerdePrincipal))
                else
                  ElevatedButton.icon(
                    onPressed: _salvar,
                    icon: const Icon(Icons.add_task, size: 20),
                    label: const Text(
                      'REGISTRAR TRATAMENTO',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corVerdePrincipal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                const SizedBox(height: 28),

                // CARD 2: HISTÓRICO DE TRATAMENTOS
                _buildCardSection(
                  children: [
                    _buildSectionHeader(
                      'HISTÓRICO REGISTRADO',
                      Icons.history,
                      subtitle: 'Registros anteriores de aplicações de medicamentos e vacinas.',
                    ),
                    if (_carregandoHistorico)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator(color: corVerdePrincipal)),
                      )
                    else if (_historico.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Nenhum tratamento registrado para este animal.',
                            style: TextStyle(color: corTextoSecundario.withOpacity(0.8), fontSize: 13),
                          ),
                        ),
                      )
                    else
                      ..._historico.map((t) {
                        final medicamentoText = t['medicamento']?.toString().trim();
                        final temMedicamento = medicamentoText != null && medicamentoText.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: corFundo,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: corBordaInput),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medical_services_outlined, size: 16, color: corVerdePrincipal),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      temMedicamento ? medicamentoText : 'Tratamento sem nome informado',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: corTextoPrimario,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Início: ${_formatarDataTexto(t['data_inicio'])}  •  Carência até: ${_formatarDataTexto(t['data_fim_carencia'])}',
                                style: const TextStyle(fontSize: 12, color: corTextoSecundario),
                              ),
                              if (t['observacoes']?.toString().isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t['observacoes'],
                                  style: TextStyle(fontSize: 12, color: corTextoPrimario.withOpacity(0.8)),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}