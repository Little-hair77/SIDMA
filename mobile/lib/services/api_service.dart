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
}