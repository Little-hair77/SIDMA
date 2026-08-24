import 'dart:typed_data';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Detecta automaticamente o endereço correto do backend conforme a plataforma:
  // - Web: 127.0.0.1 (o navegador roda na própria máquina onde o Django está)
  // - Emulador Android: 10.0.2.2 (alias especial que aponta para o localhost do PC hospedeiro)
  // - iOS simulator / outros: 127.0.0.1
  //
  // ATENÇÃO: se for testar em um CELULAR FÍSICO (não emulador), troque o valor abaixo
  // pelo IP da sua máquina na rede local (ex: "http://192.168.0.15:8000/api/"),
  // descoberto com `ipconfig` no PowerShell — com o celular na mesma rede Wi-Fi do PC.
  static String _resolverBaseUrl() {
    if (kIsWeb) return "http://127.0.0.1:8000/api/";
    if (Platform.isAndroid) return "http://10.0.2.2:8000/api/";
    return "http://127.0.0.1:8000/api/";
  }

  final String _baseUrl = _resolverBaseUrl();
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _chaveAccessToken = 'access_token';
  static const _chaveRefreshToken = 'refresh_token';
  static const _chaveUsuarioEmail = 'usuario_email';
  static const _chaveUsuarioNome = 'usuario_nome';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15); 
    _dio.options.receiveTimeout = const Duration(seconds: 15); 

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: _chaveAccessToken);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            final renovou = await _tentarRenovarToken();
            if (renovou) {
              final novaOpcoes = error.requestOptions;
              final novoToken = await _storage.read(key: _chaveAccessToken);
              novaOpcoes.headers['Authorization'] = 'Bearer $novoToken';
              try {
                final resposta = await _dio.fetch(novaOpcoes);
                return handler.resolve(resposta);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> fazerLoginGoogle(String idToken) async {
    try {
      final response = await _dio.post("auth/google/", data: {"id_token": idToken});
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        await _salvarSessao(response.data);
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Erro no login com Google: ${e.message}");
      return false;
    }
  }

  Future<Map<String, dynamic>> fazerLogin(String email, String senha) async {
    try {
      final response = await _dio.post("auth/login/", data: {"email": email, "senha": senha});
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        await _salvarSessao(response.data);
        return {'sucesso': true};
      }
      return {'sucesso': false, 'mensagem': response.data['mensagem'] ?? 'Erro ao entrar.'};
    } on DioException catch (e) {
      final mensagem = e.response?.data?['mensagem'] ?? 'Erro ao conectar com o servidor.';
      return {'sucesso': false, 'mensagem': mensagem};
    }
  }

  Future<Map<String, dynamic>> registrar(String nome, String email, String senha) async {
    try {
      final response = await _dio.post("auth/registrar/", data: {"nome": nome, "email": email, "senha": senha});
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        await _salvarSessao(response.data);
        return {'sucesso': true};
      }
      return {'sucesso': false, 'mensagem': response.data['mensagem'] ?? 'Erro ao criar conta.'};
    } on DioException catch (e) {
      final mensagem = e.response?.data?['mensagem'] ?? 'Erro ao conectar com o servidor.';
      return {'sucesso': false, 'mensagem': mensagem};
    }
  }

  Future<void> _salvarSessao(Map<String, dynamic> dados) async {
    await _storage.write(key: _chaveAccessToken, value: dados['access']);
    await _storage.write(key: _chaveRefreshToken, value: dados['refresh']);
    final usuario = dados['usuario'];
    if (usuario != null) {
      await _storage.write(key: _chaveUsuarioEmail, value: usuario['email'] ?? '');
      await _storage.write(key: _chaveUsuarioNome, value: usuario['nome'] ?? '');
    }
  }

  Future<bool> _tentarRenovarToken() async {
    final refreshToken = await _storage.read(key: _chaveRefreshToken);
    if (refreshToken == null) return false;
    try {
      final response = await Dio().post("${_baseUrl}token/refresh/", data: {"refresh": refreshToken});
      if (response.statusCode == 200) {
        await _storage.write(key: _chaveAccessToken, value: response.data['access']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> estaLogado() async {
    final token = await _storage.read(key: _chaveAccessToken);
    return token != null;
  }

  Future<Map<String, String>> obterUsuarioSalvo() async {
    final email = await _storage.read(key: _chaveUsuarioEmail) ?? '';
    final nome = await _storage.read(key: _chaveUsuarioNome) ?? '';
    return {'email': email, 'nome': nome};
  }

  Future<void> logout() async {
    await _storage.delete(key: _chaveAccessToken);
    await _storage.delete(key: _chaveRefreshToken);
    await _storage.delete(key: _chaveUsuarioEmail);
    await _storage.delete(key: _chaveUsuarioNome);
  }

  Future<Map<String, dynamic>?> enviarAnaliseLeite(Uint8List imagemBytes, String fileName, {int? animalId}) async {
    try {
      FormData formData = FormData.fromMap({
        "imagem": MultipartFile.fromBytes(imagemBytes, filename: fileName),
        if (animalId != null) "animal_id": animalId,
      });
      Response response = await _dio.post("diagnosticar/", data: formData);
      if (response.statusCode == 200) return response.data;
      return null;
    } on DioException catch (e) {
      print("Erro na requisição Dio: ${e.message}");
      return null;
    } catch (e) {
      print("Erro inesperado: $e");
      return null;
    }
  }

  Future<List<dynamic>?> buscarHistorico() async {
    try {
      final response = await _dio.get("historico/");
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') return response.data['analises'];
      return null;
    } on DioException catch (e) {
      print("Erro ao buscar histórico: ${e.message}");
      return null;
    }
  }

  Future<List<dynamic>?> buscarHistoricoFiltrado({String? resultado, String? dataInicio, String? dataFim, int? animalId}) async {
    try {
      final params = <String, dynamic>{};
      if (resultado != null) params['resultado'] = resultado;
      if (dataInicio != null) params['data_inicio'] = dataInicio;
      if (dataFim != null) params['data_fim'] = dataFim;
      if (animalId != null) params['animal_id'] = animalId;

      final response = await _dio.get("historico/", queryParameters: params);
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') return response.data['analises'];
      return null;
    } on DioException catch (e) {
      print("Erro ao buscar histórico filtrado: ${e.message}");
      return null;
    }
  }

  Future<Map<String, dynamic>?> buscarDetalheAnalise(int id) async {
    try {
      final response = await _dio.get("analises/$id/");
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') return response.data['analise'];
      return null;
    } on DioException catch (e) {
      print("Erro ao buscar detalhe da análise: ${e.message}");
      return null;
    }
  }

  Future<bool> atualizarAnalise(int id, {String? observacoes, int? animalId, bool desvincularAnimal = false, int? ccsLaboratorial, bool limparCcs = false}) async {
    try {
      final dados = <String, dynamic>{};
      if (observacoes != null) dados['observacoes'] = observacoes;
      if (desvincularAnimal) dados['animal_id'] = null;
      else if (animalId != null) dados['animal_id'] = animalId;
      if (limparCcs) dados['ccs_laboratorial'] = null;
      else if (ccsLaboratorial != null) dados['ccs_laboratorial'] = ccsLaboratorial;

      final response = await _dio.patch("analises/$id/", data: dados);
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Erro ao atualizar análise: ${e.message}");
      return false;
    }
  }

  Future<List<dynamic>?> listarTratamentos(int animalId) async {
    try {
      final response = await _dio.get("animais/$animalId/tratamentos/");
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') return response.data['tratamentos'];
      return null;
    } on DioException catch (e) {
      print("Erro ao listar tratamentos: ${e.message}");
      return null;
    }
  }

  Future<Map<String, dynamic>> registrarTratamento(int animalId, String medicamento, String dataInicio, String dataFimCarencia, String observacoes) async {
    try {
      final response = await _dio.post("animais/$animalId/tratamentos/", data: {
        "medicamento": medicamento,
        "data_inicio": dataInicio,
        "data_fim_carencia": dataFimCarencia,
        "observacoes": observacoes,
      });
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        return {'sucesso': true};
      }
      return {'sucesso': false, 'mensagem': response.data['mensagem'] ?? 'Erro ao registrar tratamento.'};
    } on DioException catch (e) {
      final mensagem = e.response?.data?['mensagem'] ?? 'Erro ao conectar com o servidor.';
      return {'sucesso': false, 'mensagem': mensagem};
    }
  }

  Future<List<dynamic>?> listarAnimais() async {
    try {
      final response = await _dio.get("animais/");
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') return response.data['animais'];
      return null;
    } on DioException catch (e) {
      print("Erro ao listar animais: ${e.message}");
      return null;
    }
  }

  // - MÉTODOS DE ANIMAIS COM FORMDATA 

  Future<Map<String, dynamic>> cadastrarAnimal(String brinco, String nome, String raca, String? dataNascimento, {String sexo = 'Fêmea', String? peso, String? observacoes, Uint8List? fotoBytes}) async {
    try {
      FormData formData = FormData.fromMap({
        "brinco": brinco,
        "nome": nome,
        "raca": raca,
        "sexo": sexo,
        if (dataNascimento != null) "data_nascimento": dataNascimento,
        if (peso != null && peso.isNotEmpty) "peso": peso,
        if (observacoes != null && observacoes.isNotEmpty) "observacoes": observacoes,
      });

      if (fotoBytes != null) {
        formData.files.add(MapEntry("foto", MultipartFile.fromBytes(fotoBytes, filename: "foto_animal_$brinco.jpg")));
      }

      final response = await _dio.post("animais/", data: formData);
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        return {'sucesso': true, 'animal': response.data['animal']};
      }
      return {'sucesso': false, 'mensagem': response.data['mensagem'] ?? 'Erro ao cadastrar animal.'};
    } on DioException catch (e) {
      final mensagem = e.response?.data?['mensagem'] ?? 'Erro ao conectar com o servidor.';
      return {'sucesso': false, 'mensagem': mensagem};
    }
  }

  Future<Map<String, dynamic>> atualizarAnimal(int id, String brinco, String nome, String raca, String? dataNascimento, {String sexo = 'Fêmea', String? peso, String? observacoes, Uint8List? fotoBytes}) async {
    try {
      FormData formData = FormData.fromMap({
        "brinco": brinco,
        "nome": nome,
        "raca": raca,
        "sexo": sexo,
        if (dataNascimento != null) "data_nascimento": dataNascimento,
        if (peso != null && peso.isNotEmpty) "peso": peso,
        if (observacoes != null && observacoes.isNotEmpty) "observacoes": observacoes,
      });

      if (fotoBytes != null) {
        formData.files.add(MapEntry("foto", MultipartFile.fromBytes(fotoBytes, filename: "foto_animal_$brinco.jpg")));
      }

      final response = await _dio.put("animais/$id/", data: formData);
      
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        return {'sucesso': true};
      }
      return {'sucesso': false, 'mensagem': response.data['mensagem'] ?? 'Erro ao atualizar animal.'};
    } on DioException catch (e) {
      final mensagem = e.response?.data?['mensagem'] ?? 'Erro ao conectar com o servidor.';
      return {'sucesso': false, 'mensagem': mensagem};
    }
  }

  Future<bool> excluirAnimal(int id) async {
    try {
      final response = await _dio.delete("animais/$id/");
      return response.statusCode == 200;
    } on DioException catch (e) {
      print("Erro ao excluir animal: ${e.message}");
      return false;
    }
  }
}