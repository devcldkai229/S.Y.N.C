import 'package:dio/dio.dart';
import 'package:sync_app/core/network/dio_errors.dart';

/// Runs [action] once; retries only on transient server errors (5xx), not timeouts/4xx.
Future<T> retryAsync<T>(
  Future<T> Function() action, {
  int maxAttempts = 2,
  Duration delay = const Duration(seconds: 1),
}) async {
  Object? lastError;
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e) {
      lastError = e;
      if (!_shouldRetry(e) || attempt >= maxAttempts) break;
      await Future<void>.delayed(delay);
    }
  }
  throw lastError!;
}

bool _shouldRetry(Object error) {
  if (error is! DioException) return false;
  if (isConnectivityDioError(error)) return false;
  final status = error.response?.statusCode;
  if (status != null && status < 500) return false;
  return status == null || status >= 500;
}
