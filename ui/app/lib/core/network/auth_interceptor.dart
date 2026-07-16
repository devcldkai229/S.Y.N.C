import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sync_app/core/network/auth_storage_keys.dart';
import 'package:sync_app/core/network/token_refresh_coordinator.dart';

/// Attaches Bearer tokens and silently refreshes on 401 (single retry).
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required FlutterSecureStorage storage,
    required TokenRefreshCoordinator coordinator,
    required Dio dio,
  })  : _storage = storage,
        _coordinator = coordinator,
        _dio = dio;

  final FlutterSecureStorage _storage;
  final TokenRefreshCoordinator _coordinator;
  final Dio _dio;

  /// Back-compat alias used across hubs.
  static const accessTokenKey = AuthStorageKeys.accessToken;

  static const _retriedExtraKey = 'auth_retried';

  static const _skipRefreshPaths = <String>{
    '/v1/auth/login',
    '/v1/auth/google',
    '/v1/auth/refresh',
    '/v1/auth/register',
    '/v1/auth/init-registration',
    '/v1/auth/complete-registration',
    '/v1/auth/finish-registration',
    '/v1/auth/resend-verification',
    '/v1/auth/forgot-password',
    '/v1/auth/reset-password',
    '/v1/auth/verify-email',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      var token = await _storage.read(key: AuthStorageKeys.accessToken);
      if (token != null &&
          token.isNotEmpty &&
          TokenRefreshCoordinator.isAccessTokenExpired(token) &&
          !_shouldSkipRefresh(options.path)) {
        token = await _coordinator.refreshAccessToken();
      }
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // Proceed without Authorization — server will 401 if required.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    if (_shouldSkipRefresh(options.path) || options.extra[_retriedExtraKey] == true) {
      handler.next(err);
      return;
    }

    final token = await _coordinator.refreshAccessToken();
    if (token == null || token.isEmpty) {
      handler.next(err);
      return;
    }

    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedExtraKey] = true;

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _shouldSkipRefresh(String path) {
    final normalized = path.contains('?') ? path.split('?').first : path;
    for (final skip in _skipRefreshPaths) {
      if (normalized.endsWith(skip) || normalized.contains(skip)) {
        return true;
      }
    }
    return false;
  }
}
