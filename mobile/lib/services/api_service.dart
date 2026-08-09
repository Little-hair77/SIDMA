import 'dart:typed_data';
import 'package:dio/dio.dart';

class ApiService {
  // Será substituido pelo IP da sua máquina local ou servidor onde o Django rodará
  // 
  final String _baseUrl = "http://127.0.0.1:8000/api/";
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15); // 15s para conectar
    _dio.options.receiveTimeout = const Duration(seconds: 15); // 15s para responder
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