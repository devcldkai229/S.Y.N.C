import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import 'package:sync_app/core/network/dio_errors.dart';
import 'package:sync_app/core/network/token_refresh_coordinator.dart';
import '../config/app_config.dart';

final _logger = Logger();

/// Dio without auth interceptor — used only for `/v1/auth/refresh`.
Dio createBareDio({String? baseUrl}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.isProduction ? 15 : 10),
      receiveTimeout: Duration(seconds: AppConfig.isProduction ? 15 : 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
}

Dio createDio({
  required FlutterSecureStorage storage,
  required TokenRefreshCoordinator coordinator,
  String? baseUrl,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? AppConfig.baseUrl,
      connectTimeout: Duration(seconds: AppConfig.isProduction ? 15 : 10),
      receiveTimeout: Duration(seconds: AppConfig.isProduction ? 15 : 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      storage: storage,
      coordinator: coordinator,
      dio: dio,
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
          final detail = describeDioError(error);
          if (isOptionalApiDioError(error)) {
            _logger.w('[NET] $detail');
          } else {
            _logger.e('[ERR] $detail — ${error.message}');
          }
          handler.next(error);
        },
      ),
    );
  }

  return dio;
}
