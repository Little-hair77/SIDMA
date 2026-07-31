import 'dart:io';
import 'package:dio/dio.dart';

class ApiService {
  // Será substituido pelo IP da sua máquina local ou servidor onde o Django rodará
  // 
  final String _baseUrl = "http://10.0.2.2:8000/api/";
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15); // 15s para conectar
    _dio.options.receiveTimeout = const Duration(seconds: 15); // 15s para responder
  }

  Future<Map<String, dynamic>?> enviarAnaliseLeite(File imagemFile) async {    
    try {
      // Obtém o nome do arquivo para estruturar no FormData
      String fileName = imagemFile.path.split('/').last;
      // Cria os dados do formulário com o arquivo de imagem
      FormData formData = FormData.fromMap({
        "imagem": await MultipartFile.fromFile(
          imagemFile.path,
          filename: fileName,
        ),
        // Será adicionado os campos extras, como id_animal, se quiser
      });

      // Faz as requisições POST para o endpoint que será mapeado no Django
      Response response = await _dio.post(
        "diagnosticar/",
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200){
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
}