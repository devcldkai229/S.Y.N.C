import 'package:dio/dio.dart';

bool isConnectivityDioError(DioException error) {
  return error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.connectionError;
}

bool isOptionalApiDioError(DioException error) {
  final status = error.response?.statusCode;
  return status == 401 ||
      status == 404 ||
      status == 429 ||
      status == 502 ||
      status == 503 ||
      isConnectivityDioError(error);
}

String describeDioError(DioException error) {
  final method = error.requestOptions.method;
  final uri = error.requestOptions.uri;
  final status = error.response?.statusCode;
  if (status != null) return '$method $uri → HTTP $status';
  return '$method $uri → ${error.type.name}';
}
