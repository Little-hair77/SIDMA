import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Tela de histórico e registro de Contagem de Células Somáticas (CCS)
/// de um animal específico.
///
/// Uso (a partir da tela de detalhe do animal, por exemplo):
///   Navigator.of(context).push(
///     MaterialPageRoute(builder: (_) => TelaRegistrarCcs(animal: _animal)),
///   );
///
/// Espera que `animal` seja o Map já usado nas demais telas do app
/// (precisa conter ao menos 'id' e 'brinco').
class TelaRegistrarCcs extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TelaRegistrarCcs({Key? key, required this.animal}) : super(key: key);

  @override
  State<TelaRegistrarCcs> createState() => _TelaRegistrarCcsState();
}

class _TelaRegistrarCcsState extends State<TelaRegistrarCcs> {
  final ApiService _apiService = ApiService();

  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  List<dynamic> _registros = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarRegistros();
  }

  Future<void> _carregarRegistros() async {
    setState(() => _carregando = true);
    final registros = await _apiService.listarRegistrosCcs(widget.animal['id']);
    if (!mounted) return;
    setState(() {
      _registros = registros ?? [];
      _carregando = false;
    });
  }

  Color _corDoRisco(String? risco) {
    switch (risco) {
      case 'ALTO':
        return Colors.redAccent;
      case 'MODERADO':
        return Colors.orange;
      default:
        return corVerdeEscuro;
    }
  }

  IconData _iconeDoRisco(String? risco) {
    switch (risco) {
      case 'ALTO':
        return Icons.warning_amber_rounded;
      case 'MODERADO':
        return Icons.info_outline;
      default:
        return Icons.check_circle_outline;
    }
  }

  String _formatarData(String? dataIso) {
    final data = DateTime.tryParse(dataIso ?? '');
    if (data == null) return dataIso ?? '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarValor(dynamic valor) {
    final numero = int.tryParse(valor.toString()) ?? 0;
    final texto = numero.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < texto.length; i++) {
      final posicaoDoFim = texto.length - i;
      buffer.write(texto[i]);
      if (posicaoDoFim > 1 && posicaoDoFim % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  Future<void> _confirmarExclusao(int registroId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir registro'),
        content: const Text('Deseja excluir este registro de CCS?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await _apiService.excluirRegistroCcs(widget.animal['id'], registroId);
      if (sucesso) _carregarRegistros();
    }
  }

  Future<void> _abrirFormularioNovoRegistro() async {
    final valorController = TextEditingController();
    final laboratorioController = TextEditingController();
    final observacoesController = TextEditingController();
    DateTime dataColeta = DateTime.now();
    final formKey = GlobalKey<FormState>();
    bool enviando = false;
    String? erro;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (contextoModal) {
        return StatefulBuilder(
          builder: (contextoModal, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(contextoModal).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Novo registro de CCS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: corTextoPrimario)),
                    const SizedBox(height: 4),
                    Text('Animal: ${widget.animal['brinco']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: valorController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valor da CCS (células/mL)',
                        border: OutlineInputBorder(),
                        helperText: 'Ex: 250000',
                      ),
                      validator: (valor) {
                        if (valor == null || valor.trim().isEmpty) return 'Informe o valor';
                        if (int.tryParse(valor.trim()) == null) return 'Informe apenas números';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final selecionada = await showDatePicker(
                          context: contextoModal,
                          initialDate: dataColeta,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (selecionada != null) setModalState(() => dataColeta = selecionada);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Data da coleta', border: OutlineInputBorder()),
                        child: Text(_formatarData(dataColeta.toIso8601String())),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: laboratorioController,
                      decoration: const InputDecoration(labelText: 'Laboratório (opcional)', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: observacoesController,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Observações (opcional)', border: OutlineInputBorder()),
                    ),
                    if (erro != null) ...[
                      const SizedBox(height: 12),
                      Text(erro!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: enviando
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                enviando = true;
                                erro = null;
                              });

                              final dataFormatada =
                                  '${dataColeta.year.toString().padLeft(4, '0')}-${dataColeta.month.toString().padLeft(2, '0')}-${dataColeta.day.toString().padLeft(2, '0')}';

                              final resultado = await _apiService.registrarCcs(
                                widget.animal['id'],
                                int.parse(valorController.text.trim()),
                                dataFormatada,
                                laboratorio: laboratorioController.text.trim(),
                                observacoes: observacoesController.text.trim(),
                              );

                              if (resultado['sucesso'] == true) {
                                if (contextoModal.mounted) Navigator.of(contextoModal).pop();
                                _carregarRegistros();
                              } else {
                                setModalState(() {
                                  enviando = false;
                                  erro = resultado['mensagem'] ?? 'Erro ao registrar CCS.';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: corVerdeEscuro,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: enviando
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('SALVAR REGISTRO', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        title: Text('CCS — ${widget.animal['brinco']}', style: const TextStyle(color: corTextoPrimario, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioNovoRegistro,
        backgroundColor: corVerdeEscuro,
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _registros.isEmpty
              ? _construirEstadoVazio()
              : RefreshIndicator(
                  onRefresh: _carregarRegistros,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: _registros.length,
                    itemBuilder: (contexto, indice) => _construirCartaoRegistro(_registros[indice]),
                  ),
                ),
    );
  }

  Widget _construirEstadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Nenhum registro de CCS ainda.\nToque em "Novo registro" para adicionar o primeiro resultado laboratorial.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construirCartaoRegistro(dynamic registro) {
    final String risco = registro['risco'] ?? 'BAIXO';
    final cor = _corDoRisco(risco);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(_iconeDoRisco(risco), color: cor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_formatarValor(registro['valor_ccs'])} céls/mL',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: corTextoPrimario),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: cor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        registro['risco_display'] ?? '',
                        style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Coleta: ${_formatarData(registro['data_coleta'])}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                if ((registro['laboratorio'] ?? '').toString().isNotEmpty)
                  Text('Laboratório: ${registro['laboratorio']}', style: const TextStyle(color: Colors.black54, fontSize: 13)),
                if ((registro['observacoes'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(registro['observacoes'], style: const TextStyle(color: Colors.black87, fontSize: 13, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _confirmarExclusao(registro['id']),
          ),
        ],
      ),
    );
  }
}