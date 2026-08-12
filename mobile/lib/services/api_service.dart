import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Será substituido pelo IP da sua máquina local ou servidor onde o Django rodará
  final String _baseUrl = "http://127.0.0.1:8000/api/";
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _chaveAccessToken = 'access_token';
  static const _chaveRefreshToken = 'refresh_token';
  static const _chaveUsuarioEmail = 'usuario_email';
  static const _chaveUsuarioNome = 'usuario_nome';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15); // 15s para conectar
    _dio.options.receiveTimeout = const Duration(seconds: 15); // 15s para responder

    // Interceptor: anexa automaticamente o token JWT em toda requisição
    // e tenta renovar o access token se expirar (401).
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
              // Repete a requisição original com o novo token
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

  // Envia o ID token do Google para o backend e guarda os tokens JWT retornados
  Future<bool> fazerLoginGoogle(String idToken) async {
    try {
      final response = await _dio.post(
        "auth/google/",
        data: {"id_token": idToken},
      );

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

  // Login tradicional por e-mail e senha
  Future<Map<String, dynamic>> fazerLogin(String email, String senha) async {
    try {
      final response = await _dio.post(
        "auth/login/",
        data: {"email": email, "senha": senha},
      );

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

  // Cadastro de nova conta (nome, e-mail, senha) — já loga automaticamente ao final
  Future<Map<String, dynamic>> registrar(String nome, String email, String senha) async {
    try {
      final response = await _dio.post(
        "auth/registrar/",
        data: {"nome": nome, "email": email, "senha": senha},
      );

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
      final response = await Dio().post(
        "${_baseUrl}token/refresh/",
        data: {"refresh": refreshToken},
      );
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

  Future<Map<String, dynamic>?> enviarAnaliseLeite(Uint8List imagemBytes, String fileName) async {
    try {
      // Cria os dados do formulário com os bytes da imagem (funciona em web e mobile)
      FormData formData = FormData.fromMap({
        "imagem": MultipartFile.fromBytes(
          imagemBytes,
          filename: fileName,
        ),
        // Será adicionado os campos extras, como id_animal, se quiser
      });

      // Faz as requisições POST para o endpoint que será mapeado no Django
      Response response = await _dio.post(
        "diagnosticar/",
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data; // Retorna o JSON estruturado enviado pelo Django
      }
      return null;
    } on DioException catch (e) {
      // Tratamento de erros de rede específicos do Dio
      print("Erro na requisição Dio: ${e.message}");
      if (e.type == DioExceptionType.connectionTimeout) {
        print("Erro: Tempo limite de conexão esgotado. Verifique o sinal de internet.");
      }
      return null;
    } catch (e) {
      print("Erro inesperado: $e");
      return null;
    }
  }

  Future<List<dynamic>?> buscarHistorico() async {
    try {
      final response = await _dio.get("historico/");
      if (response.statusCode == 200 && response.data['status'] == 'sucesso') {
        return response.data['analises'] as List<dynamic>;
      }
      return null;
    } on DioException catch (e) {
      print("Erro ao buscar histórico: ${e.message}");
      return null;
    }
  }
}