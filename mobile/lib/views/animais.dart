import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../core/cores.dart'; 
import 'cadastro_animal.dart';
import 'qrCode_animal.dart';
import 'detalhe_animal.dart';
import 'registrar_tratamento.dart';

class TelaAnimais extends StatefulWidget {
  const TelaAnimais({super.key});
  @override
  State<TelaAnimais> createState() => _TelaAnimaisState();
}

class _TelaAnimaisState extends State<TelaAnimais> {
  final ApiService _apiService = ApiService();

  List<dynamic> _animais = [];
  List<dynamic> _animaisFiltrados = [];

  bool _carregando = true;
  bool _usandoCacheOffline = false;
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _carregando = true);
    var lista = await _apiService.listarAnimais();

    bool usandoCache = false;
    if (lista == null) {
      final cache = await _apiService.obterAnimaisCacheOffline();
      if (cache != null) {
        lista = cache;
        usandoCache = true;
      }
    }

    if (!mounted) return;

    final termoAtual = _buscaController.text;

    setState(() {
      _animais = lista ?? [];
      _usandoCacheOffline = usandoCache;
      _carregando = false;
    });

    _filtrarAnimais(termoAtual);
  }

  void _filtrarAnimais(String termo) {
    if (termo.isEmpty) {
      setState(() => _animaisFiltrados = _animais);
      return;
    }

    final termoBusca = termo.toLowerCase();
    setState(() {
      _animaisFiltrados = _animais.where((animal) {
        final nome = (animal['nome'] ?? '').toString().toLowerCase();
        final brinco = (animal['brinco'] ?? '').toString().toLowerCase();
        return nome.contains(termoBusca) || brinco.contains(termoBusca);
      }).toList();
    });
  }

  Future<void> _confirmarExclusao(BuildContext context, dynamic animal) async {
    final colors = AppColors.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.superficie,
        title: Text(
          'Excluir Animal?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colors.textoPrimario,
          ),
        ),
        content: Text(
          'Tem certeza que deseja remover o animal brinco ${animal['brinco']} do rebanho? O histórico de análises não será apagado, apenas deixará de estar vinculado a esse animal.',
          style: TextStyle(color: colors.textoSecundario),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: colors.textoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colors.erro),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      setState(() => _carregando = true);

      final sucesso = await _apiService.excluirAnimal(animal['id']);

      if (!mounted) return;

      if (sucesso) {
        await _carregar();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Animal removido com sucesso.'),
            backgroundColor: colors.erro,
          ),
        );
      } else {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Não foi possível excluir o animal. Tente novamente.'),
            backgroundColor: colors.erro,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    List<dynamic> listaTratamento = [];
    List<dynamic> listaAlerta = [];
    List<dynamic> listaSaudaveis = [];

    for (var animal in _animaisFiltrados) {
      if (animal['em_carencia'] == true) {
        listaTratamento.add(animal);
      } else if (animal['alerta_reincidencia'] == true) {
        listaAlerta.add(animal);
      } else {
        listaSaudaveis.add(animal);
      }
    }

    return Scaffold(
      backgroundColor: colors.fundo,

      // APP BAR
      appBar: AppBar(
        backgroundColor: colors.destaque,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Meu Rebanho',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.primario,
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TelaCadastroAnimal()),
          );
          _carregar();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: Stack(
        children: [
          // Marca d'água
          Center(
            child: Opacity(
              opacity: 0.03,
              child: Image.asset(
                'assets/images/logoSIDMA-0.png',
                width: 250,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.pets,
                  size: 200,
                  color: colors.borda,
                ),
              ),
            ),
          ),

          Column(
            children: [
              // BARRA DE PESQUISA
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _buscaController,
                  onChanged: _filtrarAnimais,
                  style: TextStyle(color: colors.textoPrimario, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou brinco...',
                    hintStyle: TextStyle(color: colors.textoSecundario, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: colors.primario),
                    suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: colors.textoSecundario),
                            onPressed: () {
                              _buscaController.clear();
                              _filtrarAnimais('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: colors.superficie,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borda),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colors.primario, width: 1.5),
                    ),
                  ),
                ),
              ),

              if (_usandoCacheOffline && !_carregando)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.alertaFundo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 15, color: colors.alerta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem conexão — mostrando os últimos dados sincronizados.',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.alerta,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // LISTAGEM DE ANIMAIS
              Expanded(
                child: _carregando
                    ? Center(child: CircularProgressIndicator(color: colors.primario))
                    : _animais.isEmpty
                        ? _buildEmptyState(
                            colors,
                            'Nenhum animal cadastrado',
                            'Toque no "+" para adicionar o primeiro animal do rebanho.',
                          )
                        : _animaisFiltrados.isEmpty
                            ? _buildEmptyState(
                                colors,
                                'Nenhum resultado encontrado',
                                'Tente buscar por outro nome ou número de brinco.',
                              )
                            : RefreshIndicator(
                                color: colors.primario,
                                onRefresh: _carregar,
                                child: ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    if (listaTratamento.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        colors,
                                        'Em Tratamento',
                                        colors.erro,
                                        'Animais com período de carência ativo',
                                      ),
                                      ...listaTratamento.map((a) => _buildAnimalCard(context, colors, a)).toList(),
                                      const SizedBox(height: 16),
                                    ],
                                    if (listaAlerta.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        colors,
                                        'Em Análise / Alerta',
                                        colors.alerta,
                                        'Atenção necessária ou reincidência',
                                      ),
                                      ...listaAlerta.map((a) => _buildAnimalCard(context, colors, a)).toList(),
                                      const SizedBox(height: 16),
                                    ],
                                    if (listaSaudaveis.isNotEmpty) ...[
                                      _buildSectionHeader(
                                        colors,
                                        'Rebanho Saudável',
                                        colors.primario,
                                        'Sem anomalias recentes registradas',
                                      ),
                                      ...listaSaudaveis.map((a) => _buildAnimalCard(context, colors, a)).toList(),
                                    ],
                                  ],
                                ),
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(AppColors colors, String titulo, Color cor, String subtitulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitulo,
            style: TextStyle(
              fontSize: 12,
              color: colors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String texto, IconData icone, Color corTexto, Color corFundo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 12, color: corTexto),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: corTexto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(BuildContext context, AppColors colors, dynamic animal) {
    final bool emCarencia = animal['em_carencia'] == true;
    final bool alertaReincidencia = animal['alerta_reincidencia'] == true;
    final bool ccsElevado = animal['ultimo_ccs_risco'] == 'ALTO';
    final bool cioProximo = animal['cio_proximo'] == true;

    final Color corBorda = emCarencia
        ? colors.erro
        : (alertaReincidencia ? colors.alerta : Colors.transparent);

    final Color corFundoTag = emCarencia
        ? colors.erroFundo
        : (alertaReincidencia ? colors.alertaFundo : colors.primarioSuave);

    final Color corTextoTag = emCarencia
        ? colors.erro
        : (alertaReincidencia ? colors.alerta : colors.primario);

    final String textoTag = emCarencia
        ? 'Em Tratamento'
        : (alertaReincidencia ? 'Alerta / Reincidência' : 'Saudável');

    final IconData iconeTag = emCarencia
        ? Icons.medical_information
        : (alertaReincidencia ? Icons.warning_amber_rounded : Icons.check_circle_outline);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(
          left: BorderSide(
            color: corBorda != Colors.transparent ? corBorda : colors.borda,
            width: corBorda != Colors.transparent ? 4 : 1,
          ),
          top: BorderSide(color: colors.borda, width: 1),
          right: BorderSide(color: colors.borda, width: 1),
          bottom: BorderSide(color: colors.borda, width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: colors.fundo,
          backgroundImage: animal['foto'] != null ? NetworkImage(animal['foto']) : null,
          child: animal['foto'] == null
              ? Icon(Icons.pets, color: colors.textoSecundario)
              : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                animal['nome']?.isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colors.textoPrimario,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (emCarencia || alertaReincidencia)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: emCarencia ? colors.erro : colors.alerta,
                  size: 18,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Brinco: ${animal['brinco']} · ${animal['total_analises'] ?? 0} análise(s)',
              style: TextStyle(color: colors.textoSecundario, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: corFundoTag,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconeTag, size: 14, color: corTextoTag),
                  const SizedBox(width: 4),
                  Text(
                    textoTag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: corTextoTag,
                    ),
                  ),
                ],
              ),
            ),
            if (ccsElevado || cioProximo) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (ccsElevado)
                    _buildMiniTag('CCS Elevado', Icons.biotech_outlined, colors.info, colors.infoFundo),
                  if (cioProximo)
                    _buildMiniTag('Cio Previsto', Icons.favorite_outline, colors.rosa, colors.rosaFundo),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: colors.textoSecundario),
          color: colors.superficie,
          surfaceTintColor: colors.superficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'visualizar') {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)),
              );
              _carregar();
            } else if (value == 'tratamento') {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TelaRegistrarTratamento(
                    animalId: animal['id'],
                    nomeAnimal: animal['nome']?.toString().isNotEmpty == true
                        ? animal['nome']
                        : animal['brinco'],
                  ),
                ),
              );
              _carregar();
            } else if (value == 'editar') {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: animal)),
              );
              _carregar();
            } else if (value == 'qrcode') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => TelaQrCodeAnimal(animal: animal)),
              );
            } else if (value == 'excluir') {
              _confirmarExclusao(context, animal);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'visualizar',
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 20, color: colors.destaque),
                  const SizedBox(width: 12),
                  Text('Ver Ficha', style: TextStyle(color: colors.textoPrimario)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'tratamento',
              child: Row(
                children: [
                  Icon(Icons.medical_services_outlined, size: 20, color: colors.primario),
                  const SizedBox(width: 12),
                  Text('Registrar Tratamento', style: TextStyle(color: colors.textoPrimario)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 20, color: colors.textoPrimario),
                  const SizedBox(width: 12),
                  Text('Editar', style: TextStyle(color: colors.textoPrimario)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'qrcode',
              child: Row(
                children: [
                  Icon(Icons.qr_code, size: 20, color: colors.textoPrimario),
                  const SizedBox(width: 12),
                  Text('QR Code', style: TextStyle(color: colors.textoPrimario)),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'excluir',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, size: 20, color: colors.erro),
                  const SizedBox(width: 12),
                  Text(
                    'Excluir',
                    style: TextStyle(color: colors.erro, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)),
          );
          _carregar();
        },
      ),
    );
  }

  Widget _buildEmptyState(AppColors colors, String titulo, String subtitulo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined, size: 64, color: colors.textoSecundario.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colors.textoPrimario,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}