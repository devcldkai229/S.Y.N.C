import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import 'package:sync_app/features/auth/models/auth_models.dart';

class AuthService {
  AuthService(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();

  static const _deviceIdKey = 'auth_device_id';
  static const _accessTokenKey = AuthInterceptor.accessTokenKey;
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _userEmailKey = 'auth_user_email';
  static const _userNameKey = 'auth_user_name';

  bool _googleInitialized = false;

  Future<RegisterResult> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authRegister,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'deviceId': deviceId,
        'platform': _platformName,
      },
    );
    final envelope = ApiEnvelope<RegisterResult>.fromJson(
      response.data ?? <String, dynamic>{},
      RegisterResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Register failed.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final deviceId = await _getOrCreateDeviceId();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authLogin,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
        'deviceId': deviceId,
        'platform': _platformName,
      },
    );
    final envelope = ApiEnvelope<AuthSession>.fromJson(
      response.data ?? <String, dynamic>{},
      AuthSession.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Login failed.' : envelope.message);
    }

    if (rememberMe) {
      await _saveSession(envelope.data!);
    }
    return envelope.data!;
  }

  Future<AuthSession> loginWithGoogle() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        clientId: AppConfig.googleClientId.isEmpty ? null : AppConfig.googleClientId,
        serverClientId: AppConfig.googleServerClientId.isEmpty ? null : AppConfig.googleServerClientId,
      );
      _googleInitialized = true;
    }

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception(
        'Google Sign-In chưa hỗ trợ trên platform này. '
        'Hãy chạy Android/iOS hoặc cấu hình Web client ID.',
      );
    }

    final googleUser = await GoogleSignIn.instance.authenticate();
    final auth = googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google ID token bị thiếu. Hãy cấu hình GOOGLE_SERVER_CLIENT_ID '
        '(hoặc google-services) rồi thử lại.',
      );
    }

    final deviceId = await _getOrCreateDeviceId();
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authGoogle,
      data: <String, dynamic>{
        'idToken': idToken,
        'deviceId': deviceId,
        'platform': _platformName,
      },
    );
    final envelope = ApiEnvelope<AuthSession>.fromJson(
      response.data ?? <String, dynamic>{},
      AuthSession.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isEmpty ? 'Google login failed.' : envelope.message);
    }
    await _saveSession(envelope.data!);
    return envelope.data!;
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> _saveSession(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(key: _userEmailKey, value: session.email),
      _storage.write(key: _userNameKey, value: session.fullName),
    ]);
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final random = Random.secure().nextInt(1 << 32).toRadixString(16);
    final generated = 'sync-${_platformName.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}-$random';
    await _storage.write(key: _deviceIdKey, value: generated);
    return generated;
  }

  String get _platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        _logger.w('Unsupported mobile platform for auth, fallback to Web.');
        return 'Web';
    }
  }
}
