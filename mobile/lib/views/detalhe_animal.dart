import 'package:flutter/material.dart';
import 'cadastro_animal.dart';
// import 'tela_tratamentos.dart'; // Futura tela de tratamentos

class TelaDetalheAnimal extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TelaDetalheAnimal({Key? key, required this.animal}) : super(key: key);

  @override
  State<TelaDetalheAnimal> createState() => _TelaDetalheAnimalState();
}

class _TelaDetalheAnimalState extends State<TelaDetalheAnimal> {
  // Paleta AgTech baseada na imagem de referência
  static const Color corVerdeEscuro = Color.fromARGB(255, 29, 177, 86);
  static const Color corVerdeClaro = Color(0xFF74C319);
  static const Color corAzulPrincipal = Color(0xFF0D6EFD);
  static const Color corFundo = Color(0xFFF4F6F8);
  static const Color corTextoPrimario = Color(0xFF1E293B);

  late Map<String, dynamic> _animal;

  @override
  void initState() {
    super.initState();
    _animal = widget.animal;
  }

  // Lógica para calcular a idade em dias
  String _calcularIdade(String? dataIso) {
    if (dataIso == null || dataIso.isEmpty) return 'N/I';
    final dataNascimento = DateTime.tryParse(dataIso);
    if (dataNascimento == null) return 'Inválida';
    
    final diferencaDias = DateTime.now().difference(dataNascimento).inDays;
    return '$diferencaDias dias'; 
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
                // --- HEADER VERDE ---
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 50, left: 16, right: 16),
                  decoration: const BoxDecoration(
                    color: corVerdeEscuro,
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

                // --- CARD DE DETALHES 
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
                          // --- LINHA 1 - FOTO E DADOS PRINCIPAIS ---
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
                                        const Expanded(child: _TextoInfo(rotulo: 'Lactações', valor: '3 vezes')), // Placeholder p/ TCC
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    
                                    // Badges Estilo Referência
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        const _Badge(texto: '117 DEL', corFundo: corAzulPrincipal, corTexto: Colors.white), // Placeholder p/ TCC
                                        if (_animal['peso'] != null)
                                          _Badge(texto: '${_animal['peso']} Kg', corFundo: Colors.grey.shade400, corTexto: Colors.white),
                                        const _Badge(texto: 'Coberta em Lactação', corFundo: corAzulPrincipal, corTexto: Colors.white), // Placeholder p/ TCC
                                        
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

                          // --- LINHA 2 - DADOS REPRODUTIVOS E CLÍNICOS (Simulados para densidade visual) ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TextoInfo(rotulo: 'Último parto', valor: '20/01/2026\n117 dias atrás'),
                                    SizedBox(height: 12),
                                    _TextoInfo(rotulo: 'Exame IA SIDMA', valor: '04/06/2026\nSaudável'),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _TextoInfo(rotulo: 'Inseminada', valor: '05/05/2026\n12 dias atrás'),
                                    const SizedBox(height: 12),
                                    _TextoInfo(rotulo: 'Análises Totais', valor: '${_animal['total_analises'] ?? 0} exames'),
                                  ],
                                ),
                              ),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _TextoInfo(rotulo: 'Previsão Parto', valor: '09/02/2027'),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // --- OBSERVAÇÕES REAIS DO BACKEND ---
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

                          // --- LINHA 3 - BOTÕES DE AÇÃO ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Ícones Lixeira e Imprimir (Esquerda)
                              Row(
                                children: [
                                  _BotaoQuadrado(
                                    icone: Icons.delete_outline,
                                    cor: Colors.red.shade50,
                                    corIcone: Colors.redAccent,
                                    onTap: () {}, // TODO: Delete lógica
                                  ),
                                  const SizedBox(width: 8),
                                  _BotaoQuadrado(
                                    icone: Icons.print_outlined,
                                    cor: Colors.grey.shade200,
                                    corIcone: Colors.grey.shade700,
                                    onTap: () {}, // TODO: PDF lógica
                                  ),
                                ],
                              ),
                            
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {}, // Navegar para TelaTratamentos
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
                  // Logo do app com opacidade reduzida (estilo marca d'água)
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