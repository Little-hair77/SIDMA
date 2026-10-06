import 'package:flutter/material.dart';
import '../core/cores.dart';
import '../services/api_service.dart';
import 'cadastro_animal.dart';
import 'qrCode_animal.dart';
import 'detalhe_animal.dart';
import 'registrar_tratamento.dart';
import 'painel_rebanho.dart';

class TelaAnimais extends StatefulWidget {
  const TelaAnimais({Key? key}) : super(key: key);

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

  AppColors get _cores => AppColors.of(context);
  // Dark mode
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  // Paleta de Cores 
  Color get corVerdePrimaria   => _cores.primario;
  Color get corAzulMarinho     => _cores.destaque;
  Color get corTextoPrimario   => _cores.textoPrimario;
  Color get corTextoSecundario => _cores.textoSecundario;
  Color get corFundo           => _cores.fundo;

  // Dark mode
  Color get corIconeDestaque => _isDark ? _cores.textoPrimario : _cores.destaque;

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

  Future<void> _confirmarExclusao(dynamic animal) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Animal?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Tem certeza que deseja remover o animal brinco ${animal['brinco']} do rebanho? O histórico de análises não será apagado, apenas deixará de estar vinculado a esse animal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: TextStyle(color: corTextoSecundario)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
          const SnackBar(content: Text('Animal removido com sucesso.'), backgroundColor: Colors.redAccent),
        );
      } else {
        setState(() => _carregando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível excluir o animal. Tente novamente.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> listaTratamento = [];
    List<dynamic> listaAlerta = [];
    List<dynamic> listaSaudaveis = [];

    for (var animal in _animaisFiltrados) {
      final bool temRiscoCcs = animal['ultimo_ccs_risco'] == 'ALTO' || animal['ultimo_ccs_risco'] == 'MODERADO';
      final bool temCioProximo = animal['cio_proximo'] == true;

      if (animal['em_carencia'] == true) {
        listaTratamento.add(animal);
      } else if (animal['alerta_reincidencia'] == true || temRiscoCcs || temCioProximo) {
        listaAlerta.add(animal);
      } else {
        listaSaudaveis.add(animal);
      }
    }

    return Scaffold(
      backgroundColor: corFundo,
      
      // APP BAR
      appBar: AppBar(
        backgroundColor: corAzulMarinho,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_outlined),
            tooltip: 'Painel do Rebanho',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TelaPainelRebanho()),
              );
            },
          ),
        ],
      ),
      
      floatingActionButton: FloatingActionButton(
        backgroundColor: corVerdePrimaria,
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
                errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 200, color: _cores.textoDesabilitado),
              ),
            ),
          ),
          
          Column(
            children: [
              // BARRINHA DE PESQUISA
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _buscaController,
                  onChanged: _filtrarAnimais,
                  style: TextStyle(color: corTextoPrimario, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nome ou brinco...',
                    hintStyle: TextStyle(color: corTextoSecundario, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: corVerdePrimaria),
                    suffixIcon: _buscaController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: corTextoSecundario),
                            onPressed: () {
                              _buscaController.clear();
                              _filtrarAnimais('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: _cores.superficie,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _cores.borda),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _cores.borda),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: corVerdePrimaria, width: 1.5),
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
                    color: _cores.alertaFundo,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 15, color: _cores.alerta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sem conexão — mostrando os últimos dados sincronizados.',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _cores.alerta),
                        ),
                      ),
                    ],
                  ),
                ),

              // LISTAGEM DE ANIMAIS
              Expanded(
                child: _carregando
                    ? Center(child: CircularProgressIndicator(color: corVerdePrimaria))
                    : _animais.isEmpty
                        ? _buildEmptyState('Nenhum animal cadastrado', 'Toque no "+" para adicionar o primeiro animal do rebanho.')
                        : _animaisFiltrados.isEmpty
                            ? _buildEmptyState('Nenhum resultado encontrado', 'Tente buscar por outro nome ou número de brinco.')
                            : RefreshIndicator(
                                color: corVerdePrimaria,
                                onRefresh: _carregar,
                                child: ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    if (listaTratamento.isNotEmpty) ...[
                                      _buildSectionHeader('Em Tratamento', _cores.erro, 'Animais com período de carência ativo'),
                                      ...listaTratamento.map((a) => _buildAnimalCard(a)).toList(),
                                      const SizedBox(height: 16),
                                    ],
                                    if (listaAlerta.isNotEmpty) ...[
                                      _buildSectionHeader('Em Análise / Alerta', _cores.alerta, 'Atenção necessária ou reincidência'),
                                      ...listaAlerta.map((a) => _buildAnimalCard(a)).toList(),
                                      const SizedBox(height: 16),
                                    ],
                                    if (listaSaudaveis.isNotEmpty) ...[
                                      _buildSectionHeader('Rebanho Saudável', corVerdePrimaria, 'Sem anomalias recentes registradas'),
                                      ...listaSaudaveis.map((a) => _buildAnimalCard(a)).toList(),
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

  Widget _buildSectionHeader(String titulo, Color cor, String subtitulo) {
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
              color: corTextoSecundario,
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
          Text(texto, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: corTexto)),
        ],
      ),
    );
  }

  Widget _buildAnimalCard(dynamic animal) {
    final bool emCarencia = animal['em_carencia'] == true;
    final bool alertaReincidencia = animal['alerta_reincidencia'] == true;
    final bool ccsElevado = animal['ultimo_ccs_risco'] == 'ALTO';
    final bool ccsAtencao = animal['ultimo_ccs_risco'] == 'MODERADO';
    final bool cioProximo = animal['cio_proximo'] == true;

    // Selo principal do card: ordem de prioridade entre as situações
    // possíveis. Só uma aparece como selo principal por vez; as demais (se
    // houver mais de uma ao mesmo tempo) aparecem como selos extras abaixo.
    late final String textoTag;
    late final Color corTextoTag;
    late final Color corFundoTag;
    late final Color corBorda;
    late final IconData iconeTag;

    if (emCarencia) {
      textoTag = 'Em Tratamento';
      corTextoTag = _cores.erro;
      corFundoTag = _cores.erroFundo;
      corBorda = _cores.erro;
      iconeTag = Icons.medical_information;
    } else if (alertaReincidencia) {
      textoTag = 'Alerta / Reincidência';
      corTextoTag = _cores.alerta;
      corFundoTag = _cores.alertaFundo;
      corBorda = _cores.alerta;
      iconeTag = Icons.warning_amber_rounded;
    } else if (ccsElevado) {
      textoTag = 'CCS Elevado';
      corTextoTag = _cores.info;
      corFundoTag = _cores.infoFundo;
      corBorda = _cores.info;
      iconeTag = Icons.biotech_outlined;
    } else if (ccsAtencao) {
      textoTag = 'CCS em Atenção';
      corTextoTag = _cores.alerta;
      corFundoTag = _cores.alertaFundo;
      corBorda = _cores.alerta;
      iconeTag = Icons.biotech_outlined;
    } else if (cioProximo) {
      textoTag = 'Cio Previsto';
      corTextoTag = _cores.rosa;
      corFundoTag = _cores.rosaFundo;
      corBorda = _cores.rosa;
      iconeTag = Icons.favorite_outline;
    } else {
      textoTag = 'Saudável';
      corTextoTag = _cores.primarioEscuro;
      corFundoTag = _cores.primarioSuave;
      corBorda = Colors.transparent;
      iconeTag = Icons.check_circle_outline;
    }

    // Evita mostrar o mesmo motivo duas vezes (uma como selo principal,
    // outra como selo extra) quando ele já é o motivo escolhido acima.
    final bool mostrarMiniCcsElevado = ccsElevado && textoTag != 'CCS Elevado';
    final bool mostrarMiniCcsAtencao = ccsAtencao && textoTag != 'CCS em Atenção';
    final bool mostrarMiniCio = cioProximo && textoTag != 'Cio Previsto';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cores.superficie,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(_isDark ? 0.2 : 0.03), blurRadius: 8, offset: const Offset(0, 3)),
        ],
        border: Border(
          left: BorderSide(color: corBorda != Colors.transparent ? corBorda : _cores.borda, width: corBorda != Colors.transparent ? 4 : 1),
          top: BorderSide(color: _cores.borda, width: 1),
          right: BorderSide(color: _cores.borda, width: 1),
          bottom: BorderSide(color: _cores.borda, width: 1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: corFundo,
          backgroundImage: animal['foto'] != null ? NetworkImage(animal['foto']) : null,
          child: animal['foto'] == null ? Icon(Icons.pets, color: corTextoSecundario) : null,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                animal['nome']?.isNotEmpty == true ? animal['nome'] : 'Brinco ${animal['brinco']}',
                style: TextStyle(fontWeight: FontWeight.bold, color: corTextoPrimario, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (textoTag != 'Saudável')
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.warning_amber_rounded, color: corBorda != Colors.transparent ? corBorda : corTextoTag, size: 18),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Brinco: ${animal['brinco']} · ${animal['total_analises'] ?? 0} análise(s)',
              style: TextStyle(color: corTextoSecundario, fontSize: 13),
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
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: corTextoTag),
                  ),
                ],
              ),
            ),
            if (mostrarMiniCcsElevado || mostrarMiniCcsAtencao || mostrarMiniCio) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (mostrarMiniCcsElevado) _buildMiniTag('CCS Elevado', Icons.biotech_outlined, _cores.info, _cores.infoFundo),
                  if (mostrarMiniCcsAtencao) _buildMiniTag('CCS em Atenção', Icons.biotech_outlined, _cores.alerta, _cores.alertaFundo),
                  if (mostrarMiniCio) _buildMiniTag('Cio Previsto', Icons.favorite_outline, _cores.rosa, _cores.rosaFundo),
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: corTextoSecundario),
          color: _cores.superficie,
          surfaceTintColor: _cores.superficie,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'visualizar') {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaDetalheAnimal(animal: animal)));
              _carregar();
            } else if (value == 'tratamento') {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => TelaRegistrarTratamento(
                  animalId: animal['id'],
                  nomeAnimal: animal['nome']?.toString().isNotEmpty == true ? animal['nome'] : animal['brinco'],
                ),
              ));
              _carregar();
            } else if (value == 'editar') {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaCadastroAnimal(animal: animal)));
              _carregar();
            } else if (value == 'qrcode') {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => TelaQrCodeAnimal(animal: animal)));
            } else if (value == 'excluir') {
              _confirmarExclusao(animal);
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem(
              value: 'visualizar',
              child: Row(children: [Icon(Icons.visibility_outlined, size: 20, color: corIconeDestaque), const SizedBox(width: 12), Text('Ver Ficha', style: TextStyle(color: corTextoPrimario))]),
            ),
            PopupMenuItem(
              value: 'tratamento',
              child: Row(children: [Icon(Icons.medical_services_outlined, size: 20, color: corVerdePrimaria), const SizedBox(width: 12), Text('Registrar Tratamento', style: TextStyle(color: corTextoPrimario))]),
            ),
            PopupMenuItem(
              value: 'editar',
              child: Row(children: [Icon(Icons.edit_outlined, size: 20, color: corTextoPrimario), const SizedBox(width: 12), Text('Editar', style: TextStyle(color: corTextoPrimario))]),
            ),
            PopupMenuItem(
              value: 'qrcode',
              child: Row(children: [Icon(Icons.qr_code, size: 20, color: corTextoPrimario), const SizedBox(width: 12), Text('QR Code', style: TextStyle(color: corTextoPrimario))]),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'excluir',
              child: Row(children: [Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), SizedBox(width: 12), Text('Excluir', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
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

  Widget _buildEmptyState(String titulo, String subtitulo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_outlined, size: 64, color: corTextoSecundario.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: corTextoPrimario),
            ),
            const SizedBox(height: 8),
            Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: TextStyle(color: corTextoSecundario, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}