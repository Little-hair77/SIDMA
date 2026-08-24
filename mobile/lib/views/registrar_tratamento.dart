import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TelaRegistrarTratamento extends StatefulWidget {
  final int animalId;
  final String nomeAnimal;

  const TelaRegistrarTratamento({Key? key, required this.animalId, required this.nomeAnimal}) : super(key: key);

  @override
  State<TelaRegistrarTratamento> createState() => _TelaRegistrarTratamentoState();
}

class _TelaRegistrarTratamentoState extends State<TelaRegistrarTratamento> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _medicamentoController = TextEditingController();
  final _observacoesController = TextEditingController();

  // Paleta de Cores
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corTextoPrimario = Color(0xFF1E293B);

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

  String _formatarData(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _paraApi(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatarDataTexto(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return _formatarData(d);
  }

  Future<void> _escolherDataInicio() async {
    final data = await showDatePicker(context: context, initialDate: _dataInicio, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (data != null) setState(() => _dataInicio = data);
  }

  Future<void> _escolherDataFimCarencia() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataFimCarencia ?? _dataInicio.add(const Duration(days: 3)),
      firstDate: _dataInicio,
      lastDate: DateTime(2100),
    );
    if (data != null) setState(() => _dataFimCarencia = data);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dataFimCarencia == null) {
      setState(() => _erro = 'Informe a data de fim da carência.');
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
        const SnackBar(content: Text('Tratamento registrado com sucesso.')),
      );
    } else {
      setState(() {
        _erro = resultado['mensagem'];
        _carregando = false;
      });
    }
  }

  InputDecoration _estiloCampo({required String rotulo, required IconData icone}) {
    return InputDecoration(
      labelText: rotulo,
      prefixIcon: Icon(icone, color: corAzulPrincipal),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
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
        title: Text('Tratamento — ${widget.nomeAnimal}', style: const TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange),
                            SizedBox(width: 8),
                            Expanded(child: Text('Enquanto em carência, o leite desse animal não deve ser misturado ao tanque.', style: TextStyle(fontSize: 12, color: corTextoPrimario))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _medicamentoController,
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(rotulo: 'Medicamento (opcional)', icone: Icons.medication_outlined),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _escolherDataInicio,
                        child: InputDecorator(
                          decoration: _estiloCampo(rotulo: 'Data de início do tratamento', icone: Icons.calendar_today_outlined),
                          child: Text(_formatarData(_dataInicio), style: const TextStyle(color: corTextoPrimario)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: _escolherDataFimCarencia,
                        child: InputDecorator(
                          decoration: _estiloCampo(rotulo: 'Fim da carência do leite', icone: Icons.event_busy_outlined),
                          child: Text(
                            _dataFimCarencia != null ? _formatarData(_dataFimCarencia!) : 'Toque para escolher',
                            style: const TextStyle(color: corTextoPrimario),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _observacoesController,
                        maxLines: 3,
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: _estiloCampo(rotulo: 'Observações (opcional)', icone: Icons.notes_outlined),
                      ),
                      const SizedBox(height: 24),
                      if (_carregando)
                        const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
                      else
                        ElevatedButton(
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrincipal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('Registrar tratamento', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                const Text('Histórico de tratamentos', style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario, fontSize: 16)),
                const SizedBox(height: 12),
                if (_carregandoHistorico)
                  const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
                else if (_historico.isEmpty)
                  const Text('Nenhum tratamento registrado ainda.', style: TextStyle(color: Colors.grey))
                else
                  ..._historico.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t['medicamento']?.toString().isNotEmpty == true ? t['medicamento'] : 'Tratamento sem medicamento informado',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Início: ${_formatarDataTexto(t['data_inicio'])} · Carência até: ${_formatarDataTexto(t['data_fim_carencia'])}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (t['observacoes']?.toString().isNotEmpty == true) ...[
                              const SizedBox(height: 4),
                              Text(t['observacoes'], style: const TextStyle(fontSize: 13, color: corTextoPrimario)),
                            ],
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}