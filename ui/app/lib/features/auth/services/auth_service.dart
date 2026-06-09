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
      throw Exception(
        envelope.message.isEmpty ? 'Register failed.' : envelope.message,
      );
    }
    return RegisterResult.fromEnvelope(envelope);
  }

  /// Sends verification code using only full name + email (no password required).
  Future<RegisterResult> initRegistration({
    required String fullName,
    required String email,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authInitRegistration,
      data: <String, dynamic>{
        'email': email.trim(),
        'fullName': fullName.trim(),
      },
    );
    final envelope = ApiEnvelope<RegisterResult>.fromJson(
      response.data ?? <String, dynamic>{},
      RegisterResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty
            ? 'Init registration failed.'
            : envelope.message,
      );
    }
    return RegisterResult.fromEnvelope(envelope);
  }

  /// Verifies OTP; [password] is optional on this step.
  Future<VerifyEmailResult> completeRegistration({
    required String email,
    required String code,
    String? password,
  }) async {
    final data = <String, dynamic>{
      'email': email.trim(),
      'code': code.trim(),
    };
    final pwd = password?.trim();
    if (pwd != null && pwd.isNotEmpty) {
      data['password'] = pwd;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authCompleteRegistration,
      data: data,
    );
    final envelope = ApiEnvelope<VerifyEmailResult>.fromJson(
      response.data ?? <String, dynamic>{},
      VerifyEmailResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty
            ? 'Complete registration failed.'
            : envelope.message,
      );
    }
    return envelope.data!;
  }

  Future<RegisterResult> finishRegistration({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authFinishRegistration,
      data: <String, dynamic>{
        'email': email.trim(),
        'password': password,
      },
    );
    final envelope = ApiEnvelope<RegisterResult>.fromJson(
      response.data ?? <String, dynamic>{},
      RegisterResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty
            ? 'Finish registration failed.'
            : envelope.message,
      );
    }
    return RegisterResult.fromEnvelope(envelope);
  }

  Future<RegisterResult> resendVerificationCode({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authResendVerification,
      data: <String, dynamic>{'email': email.trim()},
    );
    final envelope = ApiEnvelope<RegisterResult>.fromJson(
      response.data ?? <String, dynamic>{},
      RegisterResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty
            ? 'Resend verification code failed.'
            : envelope.message,
      );
    }
    return RegisterResult.fromEnvelope(envelope);
  }

  /// Requests a 6-digit password reset code to be sent to [email].
  Future<String> forgotPassword({required String email}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authForgotPassword,
      data: <String, dynamic>{'email': email.trim()},
    );
    return _readMessage(
      response.data,
      fallback: 'If an account exists, a reset code has been sent.',
    );
  }

  /// Sets a new password using the emailed reset code.
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authResetPassword,
      data: <String, dynamic>{
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
    return _readMessage(
      response.data,
      fallback: 'Password reset successfully.',
    );
  }

  String _readMessage(Map<String, dynamic>? data, {required String fallback}) {
    final json = data ?? <String, dynamic>{};
    final success = json['success'] == true;
    final message = (json['message'] ?? '').toString();
    if (!success) {
      throw Exception(message.isEmpty ? fallback : message);
    }
    return message.isEmpty ? fallback : message;
  }

  /// Confirms email via token (same as opening the link in email / IAM log when SMTP is off).
  Future<VerifyEmailResult> verifyEmail(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      throw Exception('Verification token is required.');
    }

    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.authVerifyEmail,
      queryParameters: <String, dynamic>{'token': trimmed},
      options: Options(
        headers: <String, dynamic>{'Accept': 'application/json'},
      ),
    );
    final envelope = ApiEnvelope<VerifyEmailResult>.fromJson(
      response.data ?? <String, dynamic>{},
      VerifyEmailResult.fromJson,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(
        envelope.message.isEmpty
            ? 'Email verification failed.'
            : envelope.message,
      );
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
      throw Exception(
        envelope.message.isEmpty ? 'Login failed.' : envelope.message,
      );
    }

    if (rememberMe) {
      await _saveSession(envelope.data!);
    }
    return envelope.data!;
  }

  Future<AuthSession> loginWithGoogle() async {
    _logger.i('Google sign-in started (platform=$_platformName)');
    await _ensureGoogleSignInInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      _logger.w('Google sign-in unsupported on this platform');
      throw Exception(
        'Google Sign-In chưa hỗ trợ trên platform này. '
        'Hãy chạy Web (Chrome), Android hoặc iOS.',
      );
    }

    GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: const <String>['email', 'profile', 'openid'],
      );
    } on GoogleSignInException catch (e) {
      _logger.e(
        'Google authenticate failed: code=${e.code.name} desc=${e.description}',
      );
      rethrow;
    }
    _logger.i('Google authenticate OK (email=${googleUser.email})');
    final auth = googleUser.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      _logger.e('Google ID token missing after authenticate');
      throw Exception(
        'Google ID token bị thiếu. Hãy cấu hình GOOGLE_SERVER_CLIENT_ID '
        '(hoặc google-services) rồi thử lại.',
      );
    }

    final deviceId = await _getOrCreateDeviceId();
    _logger.i('Calling IAM Google login API...');
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
      _logger.e('IAM Google login failed: ${envelope.message}');
      throw Exception(
        envelope.message.isEmpty ? 'Google login failed.' : envelope.message,
      );
    }
    _logger.i('Google sign-in successful (email=${envelope.data!.email})');
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

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleInitialized) return;

    final clientId = AppConfig.googleClientId;
    final serverClientId = AppConfig.googleServerClientId;

    if (kIsWeb && clientId.isEmpty) {
      throw Exception(
        'Thiếu Google Web Client ID. Thêm thẻ meta google-signin-client_id trong '
        'web/index.html hoặc chạy với --dart-define=GOOGLE_CLIENT_ID=<web-client-id>.',
      );
    }

    if (!kIsWeb && serverClientId.isEmpty) {
      throw Exception(
        'Thiếu GOOGLE_SERVER_CLIENT_ID (Web OAuth client). '
        'Cần để Google trả ID token cho IAM xác minh.',
      );
    }

    _logger.i(
      'GoogleSignIn init: clientId=${_maskClientId(clientId)} '
      'serverClientId=${_maskClientId(serverClientId)}',
    );

    await GoogleSignIn.instance.initialize(
      clientId: clientId.isEmpty ? null : clientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _googleInitialized = true;
  }

  String _maskClientId(String id) {
    if (id.length <= 12) return id.isEmpty ? '(empty)' : '***';
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: _deviceIdKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    // nextInt(1 << 32) is invalid on some runtimes (shift yields 0 or max > 2^32).
    final random = List<int>.generate(
      8,
      (_) => Random.secure().nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final generated =
        'sync-${_platformName.toLowerCase()}-${DateTime.now().millisecondsSinceEpoch}-$random';
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
