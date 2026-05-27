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
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );
}
