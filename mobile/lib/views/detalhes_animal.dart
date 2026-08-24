import 'package:flutter/material.dart';
import 'cadastro_animal.dart'; // Sua tela de edição
// import 'tela_tratamentos.dart'; // Futura tela de tratamentos

class TelaDetalheAnimal extends StatefulWidget {
  final Map<String, dynamic> animal;

  const TelaDetalheAnimal({Key? key, required this.animal}) : super(key: key);

  @override
  State<TelaDetalheAnimal> createState() => _TelaDetalheAnimalState();
}

class _TelaDetalheAnimalState extends State<TelaDetalheAnimal> {
  // Paleta AgTech baseada na imagem de referência
  static const Color corVerdeEscuro = Color(0xFF1E8345);
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

  // Lógica para calcular a idade em dias, igual ao app de referência
  String _calcularIdade(String? dataIso) {
    if (dataIso == null || dataIso.isEmpty) return 'Não informada';
    final dataNascimento = DateTime.tryParse(dataIso);
    if (dataNascimento == null) return 'Inválida';
    
    final diferencaDias = DateTime.now().difference(dataNascimento).inDays;
    if (diferencaDias < 30) return '$diferencaDias dias';
    if (diferencaDias < 365) return '${(diferencaDias / 30).floor()} meses';
    
    final anos = (diferencaDias / 365).floor();
    final meses = ((diferencaDias % 365) / 30).floor();
    return '$anos anos e $meses meses';
  }

  @override
  Widget build(BuildContext context) {
    // Verificações de status vindas do backend Django
    final bool emCarencia = _animal['em_carencia'] == true;
    final bool alertaReincidencia = _animal['alerta_reincidencia'] == true;

    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corVerdeEscuro,
        foregroundColor: Colors.white,
        title: const Text('Ficha do Animal', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ==========================================
            // CARD PRINCIPAL DO ANIMAL (Baseado na Referência)
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOPO: FOTO E INFORMAÇÕES BÁSICAS ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coluna da Foto e Raça (Esquerda)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
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
                            _TextoInfo(rotulo: 'Raça', valor: _animal['raca']?.toString().toUpperCase() ?? 'N/I', centralizar: true),
                          ],
                        ),
                        const SizedBox(width: 16),
                        
                        // Coluna de Dados Vitais (Direita)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _TextoInfo(rotulo: _animal['sexo'] ?? 'Animal', valor: _animal['nome']?.isEmpty == true ? 'Sem nome' : _animal['nome']),
                                  _TextoInfo(rotulo: 'Brinco', valor: _animal['brinco']),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _TextoInfo(rotulo: 'Idade', valor: _calcularIdade(_animal['data_nascimento'])),
                                  _TextoInfo(rotulo: 'Análises IA', valor: '${_animal['total_analises'] ?? 0} exames'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Badges (Etiquetas Coloridas)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (_animal['peso'] != null)
                                    _Badge(texto: '${_animal['peso']} Kg', corFundo: Colors.grey.shade300, corTexto: Colors.black87),
                                  
                                  if (emCarencia)
                                    const _Badge(texto: 'LEITE EM CARÊNCIA', corFundo: Colors.redAccent, corTexto: Colors.white, icone: Icons.warning),
                                    
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

                    // --- OBSERVAÇÕES ---
                    if (_animal['observacoes'] != null && _animal['observacoes'].toString().isNotEmpty) ...[
                      const Text(
                        'Observações',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _animal['observacoes'],
                        style: const TextStyle(fontSize: 14, color: corTextoPrimario),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- BOTÕES DE AÇÃO (Conforme a imagem) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botões menores da esquerda (Excluir / Imprimir)
                        Row(
                          children: [
                            _BotaoQuadrado(
                              icone: Icons.delete_outline,
                              cor: Colors.red.shade50,
                              corIcone: Colors.red,
                              onTap: () {
                                // Lógica para excluir
                              },
                            ),
                            const SizedBox(width: 8),
                            _BotaoQuadrado(
                              icone: Icons.print_outlined,
                              cor: Colors.grey.shade200,
                              corIcone: Colors.grey.shade700,
                              onTap: () {
                                // Lógica para gerar PDF
                              },
                            ),
                          ],
                        ),
                        // Botões principais da direita
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navegar para TelaTratamentos(_animal['id'])
                              },
                              icon: const Icon(Icons.medical_services_outlined, size: 16, color: Colors.white),
                              label: const Text('Tratamentos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: corVerdeEscuro,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: _animal)),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
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
          ],
        ),
      ),
    );
  }
}

/// Widget que empilha um rótulo cinza pequeno em cima do valor em negrito
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          textAlign: centralizar ? TextAlign.center : TextAlign.left,
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _TelaDetalheAnimalState.corTextoPrimario),
          textAlign: centralizar ? TextAlign.center : TextAlign.left,
        ),
      ],
    );
  }
}

/// Widget para criar as "tags" azuis/cinzas 
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
            Icon(icone, size: 12, color: corTexto),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(color: corTexto, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

/// Widget para os botões quadrados inferiores esquerdos (Lixeira, Print)
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
          padding: const EdgeInsets.all(8),
          child: Icon(icone, color: corIcone, size: 20),
        ),
      ),
    );
  }
}