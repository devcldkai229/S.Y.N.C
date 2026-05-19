import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

final _logger = Logger();

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  if (!AppConfig.isProduction) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('[REQ] ${options.method} ${options.uri}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('[RES] ${response.statusCode} ${response.realUri}');
          handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('[ERR] ${error.message}');
          handler.next(error);
        },
      ),
    );
  }

  return dio;
}
