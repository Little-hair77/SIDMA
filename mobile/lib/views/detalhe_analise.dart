import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'scanner_qr.dart';

class TelaDetalheAnalise extends StatefulWidget {
  final int analiseId;
  const TelaDetalheAnalise({Key? key, required this.analiseId}) : super(key: key);

  @override
  State<TelaDetalheAnalise> createState() => _TelaDetalheAnaliseState();
}

class _TelaDetalheAnaliseState extends State<TelaDetalheAnalise> {
  final ApiService _apiService = ApiService();
  final _observacoesController = TextEditingController();

  Map<String, dynamic>? _analise;
  List<dynamic> _animais = [];
  bool _carregando = true;
  bool _salvando = false;
  bool _alterado = false;

  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corVerdePrincipal = Color(0xFF74C319);
  static const Color corFundo = Color(0xFFF8FAFC);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    final analise = await _apiService.buscarDetalheAnalise(widget.analiseId);
    final animais = await _apiService.listarAnimais();
    if (!mounted) return;
    setState(() {
      _analise = analise;
      _animais = animais ?? [];
      _observacoesController.text = analise?['observacoes'] ?? '';
      _carregando = false;
    });
  }

  Color get _corResultado {
    final resultado = _analise?['resultado'] as String? ?? '';
    if (resultado.contains('Possível')) return Colors.redAccent;
    if (resultado.contains('adicional')) return Colors.orange;
    return corVerdePrincipal;
  }

  String _formatarData(String? isoData) {
    final data = DateTime.tryParse(isoData ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} às ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _salvarObservacoes() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, observacoes: _observacoesController.text.trim());
    setState(() {
      _salvando = false;
      _alterado = false;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Observações salvas.' : 'Erro ao salvar. Tente novamente.')),
    );
  }

  Future<void> _vincularAnimal(dynamic animal) async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, animalId: animal['id']);
    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _desvincularAnimal() async {
    setState(() => _salvando = true);
    final ok = await _apiService.atualizarAnalise(widget.analiseId, desvincularAnimal: true);
    setState(() => _salvando = false);
    if (ok) _carregar();
  }

  Future<void> _escanearParaVincular() async {
    final valorLido = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const TelaScannerQr()),
    );
    if (valorLido == null) return;

    final partes = valorLido.split('|');
    dynamic animalEncontrado;
    if (partes.length == 3 && partes[0] == 'SIDMA-ANIMAL') {
      final idLido = int.tryParse(partes[1]);
      animalEncontrado = _animais.firstWhere((a) => a['id'] == idLido, orElse: () => null);
    } else {
      animalEncontrado = _animais.firstWhere((a) => a['brinco'] == valorLido, orElse: () => null);
    }

    if (animalEncontrado != null) {
      _vincularAnimal(animalEncontrado);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum animal cadastrado corresponde a esse código.')),
      );
    }
  }

  void _mostrarSeletorDeAnimal() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: corAzulPrincipal),
              title: const Text('Escanear QR Code'),
              onTap: () {
                Navigator.of(context).pop();
                _escanearParaVincular();
              },
            ),
            const Divider(height: 1),
            ..._animais.map((a) => ListTile(
                  leading: const Icon(Icons.pets, color: corVerdePrincipal),
                  title: Text(a['nome']?.isNotEmpty == true ? '${a['nome']} (${a['brinco']})' : a['brinco']),
                  onTap: () {
                    Navigator.of(context).pop();
                    _vincularAnimal(a);
                  },
                )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        iconTheme: const IconThemeData(color: corAzulPrincipal),
        title: const Text('Detalhe da Análise', style: TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold)),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: corAzulPrincipal))
          : _analise == null
              ? const Center(child: Text('Não foi possível carregar essa análise.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _analise!['imagem_url'],
                          width: double.infinity,
                          height: 260,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 260,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(_analise!['resultado'], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _corResultado)),
                      const SizedBox(height: 4),
                      Text('Confiança: ${_analise!['confianca']}', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 2),
                      Text(_formatarData(_analise!['criado_em']), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),

                      const SizedBox(height: 24),
                      const Text('Animal vinculado', style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pets, color: corVerdePrincipal),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _analise!['animal'] != null
                                    ? '${_analise!['animal']['nome']?.isNotEmpty == true ? _analise!['animal']['nome'] : ''} (${_analise!['animal']['brinco']})'
                                    : 'Nenhum animal vinculado',
                                style: const TextStyle(color: corTextoPrimario),
                              ),
                            ),
                            if (_analise!['animal'] != null)
                              IconButton(
                                icon: const Icon(Icons.link_off, size: 20, color: Colors.grey),
                                tooltip: 'Desvincular',
                                onPressed: _salvando ? null : _desvincularAnimal,
                              ),
                            TextButton(
                              onPressed: _salvando ? null : _mostrarSeletorDeAnimal,
                              child: Text(_analise!['animal'] != null ? 'Trocar' : 'Vincular', style: const TextStyle(color: corAzulPrincipal, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Text('Observações', style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _observacoesController,
                        maxLines: 4,
                        onChanged: (_) => setState(() => _alterado = true),
                        style: const TextStyle(color: corTextoPrimario),
                        decoration: InputDecoration(
                          hintText: 'Ex: vaca tratada em 10/08, aguardando retorno...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_alterado)
                        ElevatedButton(
                          onPressed: _salvando ? null : _salvarObservacoes,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corVerdePrincipal,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _salvando
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Salvar observações', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ),
    );
  }
}