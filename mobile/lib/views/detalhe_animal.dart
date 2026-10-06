import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'cadastro_animal.dart';
import 'registrar_tratamento.dart';
import 'registrar_ccs.dart';
import '../core/cores.dart';
import '../services/api_service.dart';

class TelaDetalheAnimal extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TelaDetalheAnimal({Key? key, required this.animal}) : super(key: key);

  @override
  State<TelaDetalheAnimal> createState() => _TelaDetalheAnimalState();
}

class _TelaDetalheAnimalState extends State<TelaDetalheAnimal> {
  
  AppColors get _cores => AppColors.of(context);
  // Dark mode
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  // Paleta de Cores 
  Color get corVerdePrimaria => _isDark ? _cores.primario : _cores.primarioEscuro;
  Color get corVerdeSecundaria => _cores.primario;
  Color get corAzulMarinho => _cores.destaque;
  Color get corFundo => _cores.fundo;
  Color get corCardFundo => _cores.superficie;
  Color get corTextoEscuro => _cores.textoPrimario;
  Color get corTextoSuave => _cores.textoSecundario;
  Color get corBorda => _cores.borda;

  late Map<String, dynamic> _animal;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  Future<void> _confirmarExclusao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Excluir animal', style: TextStyle(color: corTextoEscuro, fontWeight: FontWeight.bold)),
        content: Text(
          'Tem certeza? As análises já feitas não serão apagadas, mas deixarão de estar vinculadas a esse animal.',
          style: TextStyle(color: corTextoSuave),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: corTextoSuave)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Excluir', style: TextStyle(color: _cores.erro, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final sucesso = await _apiService.excluirAnimal(_animal['id']);
      if (sucesso && mounted) Navigator.of(context).pop(true);
    }
  }

  Future<void> _exportarFichaPdf() async {
    final documento = pw.Document();
    final ultimaAnalise = _animal['ultima_analise'];
    final emCarencia = _animal['em_carencia'] == true;

    documento.addPage(
      pw.Page(
        build: (contexto) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SIDMA — Ficha do Animal', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text('Gerado em: ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.Divider(),
            pw.SizedBox(height: 8),
            _linhaPdf('Brinco', _animal['brinco']?.toString() ?? 'N/I'),
            _linhaPdf('Nome', _animal['nome']?.toString().isNotEmpty == true ? _animal['nome'] : 'Sem nome'),
            _linhaPdf('Raça', _animal['raca']?.toString() ?? 'N/I'),
            _linhaPdf('Sexo', _animal['sexo']?.toString() ?? 'N/I'),
            _linhaPdf('Peso', _animal['peso'] != null ? '${_animal['peso']} Kg' : 'N/I'),
            _linhaPdf('Data de nascimento', _animal['data_nascimento'] ?? 'N/I'),
            _linhaPdf('Total de análises', '${_animal['total_analises'] ?? 0}'),
            _linhaPdf('Situação de carência', emCarencia ? 'Em carência até ${_animal['carencia_ate']}' : 'Sem restrição'),
            if ((_animal['sexo'] ?? '') == 'Fêmea') ...[
              _linhaPdf(
                'Ciclo reprodutivo',
                _animal['data_ultimo_cio'] != null
                    ? 'Último cio em ${_animal['data_ultimo_cio']} — previsão do próximo: ${_animal['previsao_proximo_cio'] ?? 'N/I'}'
                    : 'Sem registro de cio',
              ),
              _linhaPdf(
                'CCS (Contagem de Células Somáticas)',
                _animal['ultimo_ccs_valor'] != null
                    ? '${_animal['ultimo_ccs_valor']} céls/mL — ${_rotuloRiscoCcs(_animal['ultimo_ccs_risco'] as String?)} (coleta em ${_animal['ultimo_ccs_data'] ?? 'N/I'})'
                    : 'Nenhum registro de CCS',
              ),
            ],
            _linhaPdf('Última análise', ultimaAnalise != null ? '${ultimaAnalise['resultado']} (${ultimaAnalise['confianca']}) em ${ultimaAnalise['criado_em']}' : 'Nenhuma análise registrada'),
            if (_animal['observacoes']?.toString().isNotEmpty == true) ...[
              pw.SizedBox(height: 12),
              pw.Text('Observações', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text(_animal['observacoes']),
            ],
            pw.SizedBox(height: 24),
            pw.Text('Documento gerado pelo SIDMA — Sistema Inteligente de Auxílio ao Diagnóstico de Mastite.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (formato) async => documento.save());
  }

  pw.Widget _linhaPdf(String rotulo, String valor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 150, child: pw.Text(rotulo, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Expanded(child: pw.Text(valor)),
        ],
      ),
    );
  }

  String _calcularIdade(String? dataIso) {
    if (dataIso == null || dataIso.isEmpty) return 'N/I';
    final dataNascimento = DateTime.tryParse(dataIso);
    if (dataNascimento == null) return 'Inválida';
    
    final diferencaDias = DateTime.now().difference(dataNascimento).inDays;
    return '$diferencaDias dias'; 
  }

  String _formatarData(String? dataIso) {
    final data = DateTime.tryParse(dataIso ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
  }

  String _formatarDataSimples(String? dataIso) {
    final data = DateTime.tryParse(dataIso ?? '');
    if (data == null) return '';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
  }

  // Mesmos rótulos de RegistroCcs.Risco no backend (rebanho/models.py),
  // pra não ter dois textos diferentes descrevendo o mesmo risco no app.
  String _rotuloRiscoCcs(String? risco) {
    switch (risco) {
      case 'ALTO':
        return 'Risco de mastite subclínica';
      case 'MODERADO':
        return 'Atenção';
      case 'BAIXO':
        return 'Dentro do normal';
      default:
        return 'N/I';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool emCarencia = _animal['em_carencia'] == true;
    final bool alertaReincidencia = _animal['alerta_reincidencia'] == true;
    final bool cioProximo = _animal['cio_proximo'] == true;
    final bool ehFemea = (_animal['sexo'] ?? '') == 'Fêmea';
    final String? ccsRisco = _animal['ultimo_ccs_risco'] as String?;
    final bool ccsAlto = ccsRisco == 'ALTO';
    final bool ccsAtencao = ccsRisco == 'MODERADO';

    return Scaffold(
      backgroundColor: corFundo,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // HEADER 
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 48, left: 16, right: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [corAzulMarinho, corAzulMarinho],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Ficha do Animal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),
                ),

                // CARD DE CONTEÚDO PRINCIPAL
                Padding(
                  padding: const EdgeInsets.only(top: 115, left: 16, right: 16, bottom: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: corCardFundo,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: corBorda, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_isDark ? 0.2 : 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LINHA 1 - FOTO E DADOS PRINCIPAIS
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 88,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: corFundo,
                                        border: Border.all(color: corBorda),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: _animal['foto'] != null && _animal['foto'].toString().isNotEmpty
                                            ? Image.network(_animal['foto'], fit: BoxFit.cover)
                                            : Icon(Icons.pets, size: 36, color: corTextoSuave),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'RAÇA / COR',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: corTextoSuave, letterSpacing: 0.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _animal['raca']?.toString().toUpperCase() ?? 'N/I',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: corTextoEscuro),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 18),
                              
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: _TextoInfo(rotulo: _animal['sexo'] ?? 'Animal', valor: _animal['nome']?.isEmpty == true ? 'Sem nome' : _animal['nome'])),
                                        Expanded(child: _TextoInfo(rotulo: 'Brinco', valor: _animal['brinco'] ?? 'N/I')),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(child: _TextoInfo(rotulo: 'Idade', valor: _calcularIdade(_animal['data_nascimento']))),
                                        Expanded(child: _TextoInfo(rotulo: 'Análises', valor: '${_animal['total_analises'] ?? 0} exame(s)')),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    
                                    // CHIPS / BADGES 
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (_animal['peso'] != null)
                                          _Badge(texto: '${_animal['peso']} Kg', corFundo: _cores.superficieAlt, corTexto: corTextoSuave),
                                        if (_animal['sexo'] != null)
                                          _Badge(texto: _animal['sexo'].toString().toUpperCase(), corFundo: _cores.infoFundo, corTexto: _cores.info),
                                        if (emCarencia)
                                          _Badge(texto: 'CARÊNCIA', corFundo: _cores.erroFundo, corTexto: _cores.erro, icone: Icons.warning_amber_rounded),
                                        if (alertaReincidencia)
                                          _Badge(texto: 'REINCIDÊNCIA', corFundo: _cores.laranja.withOpacity(0.15), corTexto: _cores.laranja, icone: Icons.repeat_rounded),
                                        if (cioProximo)
                                          _Badge(texto: 'CIO PREVISTO', corFundo: _cores.rosaFundo, corTexto: _cores.rosa, icone: Icons.favorite_outline),
                                        if (ccsAlto)
                                          _Badge(texto: 'CCS ALTO', corFundo: _cores.infoFundo, corTexto: _cores.info, icone: Icons.biotech_outlined),
                                        if (ccsAtencao)
                                          _Badge(texto: 'CCS EM ATENÇÃO', corFundo: _cores.alertaFundo, corTexto: _cores.alerta, icone: Icons.biotech_outlined),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, thickness: 1, color: corBorda),
                          ),

                          // LINHA 2 - ANÁLISE E CARÊNCIA
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _TextoInfo(
                                  rotulo: 'Última análise',
                                  valor: _animal['ultima_analise'] != null
                                      ? '${_formatarData(_animal['ultima_analise']['criado_em'])}\n${_animal['ultima_analise']['resultado']}'
                                      : 'Nenhuma análise ainda',
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TextoInfo(rotulo: 'Análises totais', valor: '${_animal['total_analises'] ?? 0} exame(s)'),
                                    const SizedBox(height: 12),
                                    _TextoInfo(
                                      rotulo: 'Situação de carência',
                                      valor: emCarencia ? 'Até ${_formatarDataSimples(_animal['carencia_ate'])}' : 'Sem restrição',
                                    ),
                                    if (ehFemea) ...[
                                      const SizedBox(height: 12),
                                      _TextoInfo(
                                        rotulo: 'Ciclo reprodutivo',
                                        valor: _animal['data_ultimo_cio'] != null
                                            ? 'Último cio: ${_formatarDataSimples(_animal['data_ultimo_cio'])}\nPrevisão: ${_formatarDataSimples(_animal['previsao_proximo_cio'])}'
                                            : 'Sem registro de cio',
                                      ),
                                      const SizedBox(height: 12),
                                      _TextoInfo(
                                        rotulo: 'CCS (Contagem de Células Somáticas)',
                                        valor: _animal['ultimo_ccs_valor'] != null
                                            ? '${_animal['ultimo_ccs_valor']} céls/mL — ${_rotuloRiscoCcs(ccsRisco)}\nColeta: ${_formatarDataSimples(_animal['ultimo_ccs_data'])}'
                                            : 'Nenhum registro de CCS',
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // OBSERVAÇÕES
                          if (_animal['observacoes'] != null && _animal['observacoes'].toString().isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Divider(height: 1, thickness: 1, color: corBorda),
                            ),
                            Text(
                              'OBSERVAÇÕES VETERINÁRIAS',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: corTextoSuave, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _animal['observacoes'],
                              style: TextStyle(fontSize: 13, color: corTextoEscuro, height: 1.4),
                            ),
                          ],

                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Divider(height: 1, thickness: 1, color: corBorda),
                          ),

                          // LINHA 3 - BOTÕES DE AÇÃO
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  _BotaoAcaoIcone(
                                    icone: Icons.delete_outline_rounded,
                                    corFundo: _cores.erroFundo,
                                    corIcone: _cores.erro,
                                    onTap: _confirmarExclusao,
                                  ),
                                  const SizedBox(width: 8),
                                  _BotaoAcaoIcone(
                                    icone: Icons.print_outlined,
                                    corFundo: corFundo,
                                    corIcone: corTextoSuave,
                                    onTap: _exportarFichaPdf,
                                  ),
                                  const SizedBox(width: 8),
                                  _BotaoAcaoIcone(
                                    icone: Icons.biotech_outlined,
                                    corFundo: _cores.infoFundo,
                                    corIcone: _cores.info,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TelaRegistrarCcs(animal: _animal),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            
                              Row(
                                children: [
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TelaRegistrarTratamento(
                                            animalId: _animal['id'],
                                            nomeAnimal: _animal['nome']?.toString().isNotEmpty == true ? _animal['nome'] : _animal['brinco'],
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.medical_services_outlined, size: 16),
                                    label: const Text('Tratamentos\ne Pesagem', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.1)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: corVerdePrimaria,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: _animal)),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: const Text('Editar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: corVerdeSecundaria,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // RODAPÉ 
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                children: [
                  Opacity(
                    opacity: _isDark ? 0.7 : 0.4,
                    child: Image.asset('assets/images/logoSIDMA-0.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(Icons.pets, color: corTextoSuave, size: 28),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'GESTÃO INTELIGENTE DE GERENCIAMENTO',
                    style: TextStyle(
                      color: corTextoSuave,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      letterSpacing: 1.1, 
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Registro do Animal ID: #${_animal['id'] ?? 'N/A'}',
                    style: TextStyle(
                      color: _isDark ? _cores.textoSecundario : _cores.textoDesabilitado,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextoInfo extends StatelessWidget {
  final String rotulo;
  final String valor;

  const _TextoInfo({required this.rotulo, required this.valor});

  @override
  Widget build(BuildContext context) {
    final cores = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(fontSize: 11, color: cores.textoSecundario, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cores.textoPrimario, height: 1.2),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String texto;
  final Color corFundo;
  final Color corTexto;
  final IconData? icone;

  const _Badge({required this.texto, required this.corFundo, required this.corTexto, this.icone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 11, color: corTexto),
            const SizedBox(width: 3),
          ],
          Text(
            texto,
            style: TextStyle(color: corTexto, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ],
      ),
    );
  }
}

class _BotaoAcaoIcone extends StatelessWidget {
  final IconData icone;
  final Color corFundo;
  final Color corIcone;
  final VoidCallback onTap;

  const _BotaoAcaoIcone({
    required this.icone,
    required this.corFundo,
    required this.corIcone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: corFundo,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(9),
          child: Icon(icone, color: corIcone, size: 20),
        ),
      ),
    );
  }
}