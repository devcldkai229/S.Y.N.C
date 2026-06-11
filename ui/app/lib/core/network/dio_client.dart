import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import '../config/app_config.dart';

final _logger = Logger();

Dio createDio({FlutterSecureStorage? storage, String? baseUrl}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  if (storage != null) {
    dio.interceptors.add(AuthInterceptor(storage));
  }

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
