import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/core/network/auth_storage_keys.dart';
import 'package:sync_app/core/network/token_refresh_coordinator.dart';
import 'package:sync_app/core/notifications/notification_realtime_service.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/auth/models/auth_models.dart';
import 'package:sync_app/features/cyn/state/cyn_chat_session_store.dart';

class AuthService {
  AuthService(this._dio, this._storage, this._coordinator);

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final TokenRefreshCoordinator _coordinator;
  final Logger _logger = Logger();

  /// Fires when silent refresh fails and session tokens were cleared.
  Stream<void> get onSessionExpired => _coordinator.onSessionExpired;

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

  /// Confirms email via token (same as opening the link in email / IAM log when Brevo is off).
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
    } else {
      // Session-only: keep access for this process; no refresh → re-login after expiry.
      await _storage.write(
        key: AuthStorageKeys.accessToken,
        value: envelope.data!.accessToken,
      );
      await _storage.delete(key: AuthStorageKeys.refreshToken);
    }
    return envelope.data!;
  }

  // ── Web-only: called by LoginScreen when GoogleSignIn.instance.authenticationEvents
  // fires a GoogleSignInAuthenticationEventSignIn after the GIS renderButton() is clicked.
  Future<AuthSession> loginWithGoogleAccount(GoogleSignInAccount account) async {
    _logger.i('Web: processing signed-in Google account (${account.email})');
    final webAuth = account.authentication;
    final idToken = webAuth.idToken;
    return _exchangeGoogleIdToken(idToken: idToken, email: account.email);
  }

  Future<AuthSession> loginWithGoogle() async {
    _logger.i('Google sign-in started (platform=$_platformName)');

    String? idToken;
    String? signedInEmail;

    if (kIsWeb) {
      // On Web, google_sign_in_web (GIS) does NOT support authenticate().
      // Sign-in is triggered by clicking the renderButton() widget rendered in
      // the login screen. Results arrive via GoogleSignIn.instance.authenticationEvents
      // stream, which calls loginWithGoogleAccount() directly.
      // loginWithGoogle() is therefore not the Web sign-in entry point.
      throw const WebGoogleSignInRequiresButtonException();
    } else {
      // Android / iOS — use the unified instance API.
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
      signedInEmail = googleUser.email;
      _logger.i('Google authenticate OK (email=$signedInEmail)');
      final mobileAuth = googleUser.authentication;
      idToken = mobileAuth.idToken;
    }

    return _exchangeGoogleIdToken(idToken: idToken, email: signedInEmail);
  }

  Future<AuthSession> _exchangeGoogleIdToken({
    required String? idToken,
    required String? email,
  }) async {
    if (idToken == null || idToken.isEmpty) {
      _logger.e('Google ID token missing (email=$email)');
      throw Exception(
        'Google ID token bị thiếu. Hãy cấu hình GOOGLE_SERVER_CLIENT_ID '
        '(hoặc google-services) rồi thử lại.',
      );
    }
    final deviceId = await _getOrCreateDeviceId();
    _logger.i('Calling IAM Google login API (email=$email)...');
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
    // Long-lived mobile session = refresh token + deviceId on disk.
    final refresh = await _storage.read(key: AuthStorageKeys.refreshToken);
    final deviceId = await _storage.read(key: AuthStorageKeys.deviceId);
    if (refresh != null &&
        refresh.isNotEmpty &&
        deviceId != null &&
        deviceId.isNotEmpty) {
      return true;
    }
    // Ephemeral (rememberMe=false): access-only until JWT expires.
    final access = await _storage.read(key: AuthStorageKeys.accessToken);
    return access != null &&
        access.isNotEmpty &&
        !TokenRefreshCoordinator.isAccessTokenExpired(access);
  }

  /// Returns a non-expired access token, refreshing when needed.
  Future<String?> getValidAccessToken({bool notifyOnFailure = true}) =>
      _coordinator.getValidAccessToken(notifyOnFailure: notifyOnFailure);

  Future<void> logout() async {
    try {
      if (getIt.isRegistered<NotificationRealtimeService>()) {
        await getIt<NotificationRealtimeService>().stop();
      }
    } catch (_) {
      // Ignore hub stop errors during logout.
    }
    try {
      if (getIt.isRegistered<CynChatSessionStore>()) {
        getIt<CynChatSessionStore>().clear();
      }
    } catch (_) {
      // Ignore chat clear errors during logout.
    }

    await _bestEffortLogoutApi();
    await _coordinator.clearSessionTokens(emitExpired: false);
  }

  /// Revokes device refresh on IAM when access is still usable; never blocks local clear.
  Future<void> _bestEffortLogoutApi() async {
    final access = await _storage.read(key: AuthStorageKeys.accessToken);
    final deviceId = await _storage.read(key: AuthStorageKeys.deviceId);
    if (access == null ||
        access.isEmpty ||
        TokenRefreshCoordinator.isAccessTokenExpired(access) ||
        deviceId == null ||
        deviceId.isEmpty) {
      return;
    }
    try {
      await _dio.post<Map<String, dynamic>>(
        ApiPaths.authLogout,
        data: <String, dynamic>{'deviceId': deviceId},
      );
    } catch (e) {
      _logger.w('Logout API failed (continuing local clear): $e');
    }
  }

  Future<void> _saveSession(AuthSession session) =>
      _coordinator.saveSession(session);

  /// Public entry-point for UI to ensure GoogleSignIn is initialized before
  /// subscribing to [GoogleSignIn.instance.authenticationEvents] on Web.
  /// Safe to call multiple times — only initializes once.
  Future<void> ensureGoogleSignInInitialized() => _ensureGoogleSignInInitialized();

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
      // google_sign_in_web asserts serverClientId == null on Web — never pass it.
      serverClientId: (kIsWeb || serverClientId.isEmpty) ? null : serverClientId,
    );
    _googleInitialized = true;
  }

  String _maskClientId(String id) {
    if (id.length <= 12) return id.isEmpty ? '(empty)' : '***';
    return '${id.substring(0, 8)}...${id.substring(id.length - 6)}';
  }

  Future<String> _getOrCreateDeviceId() async {
    final existing = await _storage.read(key: AuthStorageKeys.deviceId);
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
    await _storage.write(key: AuthStorageKeys.deviceId, value: generated);
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

/// Thrown by [AuthService.loginWithGoogle] on Web when no cached Google session
/// exists and the UI must show [GoogleSignIn.instance.renderButton()] to let the
/// user sign in interactively via GIS.
class WebGoogleSignInRequiresButtonException implements Exception {
  const WebGoogleSignInRequiresButtonException();

  @override
  String toString() =>
      'WebGoogleSignInRequiresButtonException: use GoogleSignIn.instance.renderButton()';
}
