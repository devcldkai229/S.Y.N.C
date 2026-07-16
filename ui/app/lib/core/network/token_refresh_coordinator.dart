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
/// Rotates and persists the access+refresh pair from IAM; on failure clears
/// session tokens (keeps [AuthStorageKeys.deviceId]) and emits [onSessionExpired].
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

  /// Fires when refresh fails and local session tokens were cleared.
  Stream<void> get onSessionExpired => _sessionExpiredController.stream;

  /// Returns a non-expired access token, refreshing when needed.
  Future<String?> getValidAccessToken() async {
    final token = await _storage.read(key: AuthStorageKeys.accessToken);
    if (token != null && token.isNotEmpty && !isAccessTokenExpired(token)) {
      return token;
    }
    return refreshAccessToken();
  }

  /// Refresh once (single-flight). Returns new access token or null.
  ///
  /// Missing refresh credentials returns null without emitting [onSessionExpired].
  /// A failed refresh of an existing session clears tokens and emits.
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

      final token = await _doRefresh(
        refreshToken: refreshToken,
        deviceId: deviceId,
      );
      if (token == null && notifyOnFailure) {
        await clearSessionTokens(emitExpired: true);
      }
      completer.complete(token);
      return token;
    } catch (e, st) {
      _logger.w('Token refresh failed: $e\n$st');
      if (notifyOnFailure) {
        await clearSessionTokens(emitExpired: true);
      }
      completer.complete(null);
      return null;
    } finally {
      if (identical(_inFlight, completer)) {
        _inFlight = null;
      }
    }
  }

  Future<String?> _doRefresh({
    required String refreshToken,
    required String deviceId,
  }) async {
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
      _logger.w('Token refresh rejected: ${envelope.message}');
      return null;
    }

    final session = envelope.data!;
    await saveSession(session);
    return session.accessToken;
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

  static bool isAccessTokenExpired(String token, {Duration skew = const Duration(seconds: 30)}) {
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
