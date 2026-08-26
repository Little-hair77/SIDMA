import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'cadastro_animal.dart';
import 'registrar_tratamento.dart';
import '../services/api_service.dart';

class TelaDetalheAnimal extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TelaDetalheAnimal({Key? key, required this.animal}) : super(key: key);

  @override
  State<TelaDetalheAnimal> createState() => _TelaDetalheAnimalState();
}

class _TelaDetalheAnimalState extends State<TelaDetalheAnimal> {
  // Paleta de Cores
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corVerdeClaro = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

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
        title: const Text('Excluir animal'),
        content: const Text('Tem certeza? As análises já feitas não serão apagadas, mas deixarão de estar vinculadas a esse animal.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
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

  // Lógica para calcular a idade em dias
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

  @override
  Widget build(BuildContext context) {
    final bool emCarencia = _animal['em_carencia'] == true;
    final bool alertaReincidencia = _animal['alerta_reincidencia'] == true;

    return Scaffold(
      backgroundColor: corFundo,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // - HEADER 
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                  decoration: const BoxDecoration(
                    color: corVerdeClaro,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Ficha do Animal',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), 
                    ],
                  ),
                ),

                // - CARD DE DETALHES 
                Padding(
                  padding: const EdgeInsets.only(top: 110, left: 16, right: 16, bottom: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // - LINHA 1 - FOTO E DADOS PRINCIPAIS 
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Coluna da Esquerda (Foto + Raça)
                              SizedBox(
                                width: 90,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 90, height: 90,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade100,
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _animal['foto'] != null && _animal['foto'].toString().isNotEmpty
                                            ? Image.network(_animal['foto'], fit: BoxFit.cover)
                                            : Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Raça/Cor',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                    Text(
                                      _animal['raca']?.toString().toUpperCase() ?? 'N/I',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corTextoPrimario),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Coluna da Direita (Dados Estruturados em Grid)
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
                                    const SizedBox(height: 16),
                                    
                                    // Badges Estilo Referência
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        if (_animal['peso'] != null)
                                          _Badge(texto: '${_animal['peso']} Kg', corFundo: Colors.grey.shade400, corTexto: Colors.white),
                                        if (_animal['sexo'] != null)
                                          _Badge(texto: _animal['sexo'], corFundo: corAzulPrincipal, corTexto: Colors.white),
                                        
                                        if (emCarencia)
                                          const _Badge(texto: 'CARÊNCIA', corFundo: Colors.redAccent, corTexto: Colors.white, icone: Icons.warning),
                                        if (alertaReincidencia)
                                          const _Badge(texto: 'REINCIDÊNCIA', corFundo: Colors.orange, corTexto: Colors.white, icone: Icons.repeat),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, thickness: 1),
                          ),

                          // - LINHA 2 - ÚLTIMA ANÁLISE E CARÊNCIA 
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TextoInfo(
                                      rotulo: 'Última análise',
                                      valor: _animal['ultima_analise'] != null
                                          ? '${_formatarData(_animal['ultima_analise']['criado_em'])}\n${_animal['ultima_analise']['resultado']}'
                                          : 'Nenhuma análise ainda',
                                    ),
                                  ],
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
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // - OBSERVAÇÕES REAIS DO BACKEND
                          if (_animal['observacoes'] != null && _animal['observacoes'].toString().isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, thickness: 1),
                            ),
                            const Text(
                              'Observações Veterinárias',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _animal['observacoes'],
                              style: const TextStyle(fontSize: 14, color: corTextoPrimario),
                            ),
                          ],

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, thickness: 1),
                          ),

                          // - LINHA 3 - BOTÕES DE AÇÃO 
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Ícones Lixeira e Imprimir 
                              Row(
                                children: [
                                  _BotaoQuadrado(
                                    icone: Icons.delete_outline,
                                    cor: Colors.red.shade50,
                                    corIcone: Colors.redAccent,
                                    onTap: _confirmarExclusao,
                                  ),
                                  const SizedBox(width: 8),
                                  _BotaoQuadrado(
                                    icone: Icons.print_outlined,
                                    cor: Colors.grey.shade200,
                                    corIcone: Colors.grey.shade700,
                                    onTap: _exportarFichaPdf,
                                  ),
                                ],
                              ),
                            
                              Row(
                                children: [
                                  ElevatedButton.icon(
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
                                    icon: const Icon(Icons.medical_services, size: 16, color: Colors.white),
                                    label: const Text('Tratamentos\ne Pesagem', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: corVerdeEscuro,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: _animal)),
                                      );
                                    },
                                    icon: const Icon(Icons.edit_square, size: 16, color: Colors.white),
                                    label: const Text('Editar', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: corVerdeClaro,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

          // 3 - RODAPÉ DA TELA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Column(
                children: [
                  Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      'assets/images/logoSIDMA-1.png', 
                      height: 45,
                      fit: BoxFit.contain,
                      // Se a imagem falhar, mostra um ícone de fallback sutil
                      errorBuilder: (_, __, ___) => Icon(Icons.pets, color: Colors.grey.shade400, size: 36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Texto de Branding
                  Text(
                    'Gestão Inteligente de Gerenciamento',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.5, 
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Informação Técnica Extra (Ex: ID no Banco)
                  Text(
                    'Registro do Animal ID: #${_animal['id'] ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
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
  final bool centralizar;

  const _TextoInfo({required this.rotulo, required this.valor, this.centralizar = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centralizar ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          textAlign: centralizar ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _TelaDetalheAnimalState.corTextoPrimario, height: 1.2),
          textAlign: centralizar ? TextAlign.center : TextAlign.left,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 10, color: corTexto),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(color: corTexto, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _BotaoQuadrado extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final Color corIcone;
  final VoidCallback onTap;

  const _BotaoQuadrado({required this.icone, required this.cor, required this.corIcone, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(icone, color: corIcone, size: 22),
        ),
      ),
    );
  }
}