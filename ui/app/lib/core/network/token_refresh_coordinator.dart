import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/core/network/auth_storage_keys.dart';
import 'package:sync_app/features/auth/models/auth_models.dart';

/// Single-flight refresh using a bare [Dio] (no auth interceptor).
///
/// Mobile best practice:
/// - Rotate + persist access/refresh on success.
/// - Clear session **only** on definitive auth failure (401/403 / revoked token).
/// - Keep tokens on transient network / 5xx so the next call can retry refresh.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator({
    required FlutterSecureStorage storage,
    required Dio refreshDio,
  })  : _storage = storage,
        _refreshDio = refreshDio;

  final FlutterSecureStorage _storage;
  final Dio _refreshDio;
  final Logger _logger = Logger();

  Completer<String?>? _inFlight;
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();

  /// Fires when refresh fails definitively and local session tokens were cleared.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  /// Returns a non-expired access token, refreshing when needed.
  Future<String?> getValidAccessToken({bool notifyOnFailure = true}) async {
    final token = await _storage.read(key: AuthStorageKeys.accessToken);
    if (token != null && token.isNotEmpty && !isAccessTokenExpired(token)) {
      return token;
    }
    return refreshAccessToken(notifyOnFailure: notifyOnFailure);
  }

  /// Refresh once (single-flight). Returns new access token or null.
  ///
  /// Missing credentials → null, no expire event.
  /// Auth rejection (401/403 / invalid refresh) → clear tokens + optional expire event.
  /// Network / timeout / 5xx → keep tokens, return null (caller retries later).
  Future<String?> refreshAccessToken({bool notifyOnFailure = true}) async {
    final existing = _inFlight;
    if (existing != null) return existing.future;

    final completer = Completer<String?>();
    _inFlight = completer;
    try {
      final refreshToken = await _storage.read(key: AuthStorageKeys.refreshToken);
      final deviceId = await _storage.read(key: AuthStorageKeys.deviceId);
      if (refreshToken == null ||
          refreshToken.isEmpty ||
          deviceId == null ||
          deviceId.isEmpty) {
        completer.complete(null);
        return null;
      }

      final result = await _doRefreshWithRetry(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );

      if (result.accessToken != null) {
        completer.complete(result.accessToken);
        return result.accessToken;
      }

      if (result.definitiveAuthFailure && notifyOnFailure) {
        await clearSessionTokens(emitExpired: true);
      } else if (result.definitiveAuthFailure) {
        await clearSessionTokens(emitExpired: false);
      } else {
        _logger.w(
          'Token refresh deferred (transient): ${result.errorMessage ?? "unknown"}',
        );
      }
      completer.complete(null);
      return null;
    } catch (e, st) {
      // Unexpected — treat as transient; do not wipe a long-lived session.
      _logger.w('Token refresh unexpected error: $e\n$st');
      completer.complete(null);
      return null;
    } finally {
      if (identical(_inFlight, completer)) {
        _inFlight = null;
      }
    }
  }

  Future<_RefreshResult> _doRefreshWithRetry({
    required String refreshToken,
    required String deviceId,
  }) async {
    _RefreshResult last = await _doRefresh(
      refreshToken: refreshToken,
      deviceId: deviceId,
    );
    if (last.accessToken != null || last.definitiveAuthFailure) {
      return last;
    }
    // One soft retry for flaky mobile networks.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    last = await _doRefresh(
      refreshToken: refreshToken,
      deviceId: deviceId,
    );
    return last;
  }

  Future<_RefreshResult> _doRefresh({
    required String refreshToken,
    required String deviceId,
  }) async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiPaths.authRefresh,
        data: <String, dynamic>{
          'refreshToken': refreshToken,
          'deviceId': deviceId,
        },
      );
      final envelope = ApiEnvelope<AuthSession>.fromJson(
        response.data ?? <String, dynamic>{},
        AuthSession.fromJson,
      );
      if (!envelope.success || envelope.data == null) {
        _logger.w('Token refresh rejected by IAM: ${envelope.message}');
        return _RefreshResult.authFailure(envelope.message);
      }

      final session = envelope.data!;
      await saveSession(session);
      return _RefreshResult.success(session.accessToken);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        _logger.w('Token refresh auth failure HTTP $status');
        return _RefreshResult.authFailure(e.message);
      }
      // Timeout, connection error, 5xx, etc. — keep refresh token.
      return _RefreshResult.transient(
        e.message ?? e.type.name,
      );
    }
  }

  Future<void> saveSession(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: AuthStorageKeys.accessToken, value: session.accessToken),
      _storage.write(key: AuthStorageKeys.refreshToken, value: session.refreshToken),
      _storage.write(key: AuthStorageKeys.userEmail, value: session.email),
      _storage.write(key: AuthStorageKeys.userName, value: session.fullName),
    ]);
  }

  /// Clears auth tokens/profile cache but keeps [AuthStorageKeys.deviceId].
  Future<void> clearSessionTokens({bool emitExpired = false}) async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: AuthStorageKeys.accessToken),
      _storage.delete(key: AuthStorageKeys.refreshToken),
      _storage.delete(key: AuthStorageKeys.userEmail),
      _storage.delete(key: AuthStorageKeys.userName),
    ]);
    if (emitExpired && !_sessionExpiredController.isClosed) {
      _sessionExpiredController.add(null);
    }
  }

  /// True when a refresh token + deviceId exist (long-lived session on disk).
  Future<bool> hasPersistedSession() async {
    final refresh = await _storage.read(key: AuthStorageKeys.refreshToken);
    final deviceId = await _storage.read(key: AuthStorageKeys.deviceId);
    return refresh != null &&
        refresh.isNotEmpty &&
        deviceId != null &&
        deviceId.isNotEmpty;
  }

  static bool isAccessTokenExpired(String token, {Duration skew = const Duration(seconds: 45)}) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return true;
      final normalized = base64Url.normalize(parts[1]);
      final payload = json.decode(utf8.decode(base64Url.decode(normalized)));
      final exp = payload['exp'];
      if (exp is! num) return false;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        exp.toInt() * 1000,
        isUtc: true,
      );
      return DateTime.now().toUtc().isAfter(expiresAt.subtract(skew));
    } catch (_) {
      return true;
    }
  }

  void dispose() {
    _sessionExpiredController.close();
  }
}

class _RefreshResult {
  const _RefreshResult._({
    this.accessToken,
    required this.definitiveAuthFailure,
    this.errorMessage,
  });

  factory _RefreshResult.success(String token) => _RefreshResult._(
        accessToken: token,
        definitiveAuthFailure: false,
      );

  factory _RefreshResult.authFailure(String? message) => _RefreshResult._(
        definitiveAuthFailure: true,
        errorMessage: message,
      );

  factory _RefreshResult.transient(String message) => _RefreshResult._(
        definitiveAuthFailure: false,
        errorMessage: message,
      );

  final String? accessToken;
  final bool definitiveAuthFailure;
  final String? errorMessage;
}
