import 'package:flutter/foundation.dart';

/// API base includes `/api` prefix. Paths in [ApiPaths] start with `/v1/...`.
/// SyncPlatform Gateway mặc định: `http://localhost:5057` → base `http://localhost:5057/api`
class AppConfig {
  static const String appName = 'SYNC';

  /// Override: `flutter run --dart-define=BASE_URL=http://10.0.2.2:5057/api`
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5057/api';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:5057/api';
      default:
        return 'http://localhost:5057/api';
    }
  }

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Web OAuth 2.0 client (Google Cloud Console → **Web application**).
  /// Must also appear in IAM `GoogleAuth:ClientIds` (see appsettings.Development.json).
  static const String defaultGoogleWebClientId =
      '366172488368-4brct5chejltaa6rlk42b0pnn2a53skr.apps.googleusercontent.com';

  /// Override: `--dart-define=GOOGLE_CLIENT_ID=...` (required for Web if you change the default).
  static String get googleClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return defaultGoogleWebClientId;
    return '';
  }

  /// Override: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  /// Android/iOS: use the **Web** client ID here so Google returns an ID token IAM can verify.
  static String get googleServerClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultGoogleWebClientId;
  }
}
