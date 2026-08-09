import 'package:flutter/foundation.dart';

/// API base includes `/api` prefix. Paths in [ApiPaths] start with `/v1/...`.
/// SyncPlatform Gateway mặc định: `http://localhost:5057` → base `http://localhost:5057/api`
class AppConfig {
  static const String appName = 'SYNC';

  /// LAN IP of the dev machine running the Gateway — required for a real phone
  /// (the emulator-only alias 10.0.2.2 does NOT work on physical devices).
  /// Phone and PC must be on the same Wi‑Fi/LAN.
  /// PC Wi‑Fi IP on the same LAN as the phone (check: ipconfig → Wi‑Fi adapter).
  static const String _devLanHost = '192.168.100.118';

  /// Override: `flutter run --dart-define=BASE_URL=http://<your-ip>:5057/api`
  /// Production AAB: `--dart-define=BASE_URL=https://api.YOUR_DOMAIN/api`
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Release builds must set BASE_URL; refuse silent HTTP LAN defaults.
    if (kReleaseMode) {
      return 'https://api.sync-lifestyle.app/api';
    }
    if (kIsWeb) return 'http://localhost:5057/api';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Physical Android device: reach the Gateway via the PC's LAN IP.
        // For the Android emulator instead, pass --dart-define=BASE_URL=http://10.0.2.2:5057/api
        return 'http://$_devLanHost:5057/api';
      case TargetPlatform.iOS:
        return 'http://$_devLanHost:5057/api';
      default:
        return 'http://localhost:5057/api';
    }
  }

  /// SignalR hub on Notification service (not via Gateway). Override:
  /// `--dart-define=NOTIFICATION_HUB_URL=http://<host>:5106/hubs/notifications`
  /// Order tracking SignalR hub via Gateway (:5057/hubs/tracking). Override:
  /// `--dart-define=ORDER_TRACKING_HUB_URL=http://<host>:5057/hubs/tracking`
  static String get orderTrackingHubUrl {
    const fromEnv = String.fromEnvironment('ORDER_TRACKING_HUB_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    final apiBase = baseUrl;
    final origin = apiBase.endsWith('/api') ? apiBase.substring(0, apiBase.length - 4) : apiBase;
    return '$origin/hubs/tracking';
  }

  /// Nutrition SignalR hub (Nutrition service :5122). Override:
  /// `--dart-define=NUTRITION_HUB_URL=http://<host>:5122/hubs/nutrition`
  static String get nutritionHubUrl {
    const fromEnv = String.fromEnvironment('NUTRITION_HUB_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5122/hubs/nutrition';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'http://$_devLanHost:5122/hubs/nutrition';
      default:
        return 'http://localhost:5122/hubs/nutrition';
    }
  }

  /// Roadmap SignalR hub (Roadmap service :5118). Override:
  /// `--dart-define=ROADMAP_HUB_URL=http://<host>:5118/hubs/roadmap`
  static String get roadmapHubUrl {
    const fromEnv = String.fromEnvironment('ROADMAP_HUB_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5118/hubs/roadmap';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'http://$_devLanHost:5118/hubs/roadmap';
      default:
        return 'http://localhost:5118/hubs/roadmap';
    }
  }

  static String get notificationHubUrl {
    const fromEnv = String.fromEnvironment('NOTIFICATION_HUB_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return 'http://localhost:5106/hubs/notifications';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://$_devLanHost:5106/hubs/notifications';
      case TargetPlatform.iOS:
        return 'http://$_devLanHost:5106/hubs/notifications';
      default:
        return 'http://localhost:5106/hubs/notifications';
    }
  }

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Public legal site (deployed with `ui/web`). Override:
  /// `--dart-define=LEGAL_BASE_URL=https://sync-lifestyle.app`
  static String get legalBaseUrl {
    const fromEnv = String.fromEnvironment('LEGAL_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/$'), '');
    return 'https://sync-lifestyle.app';
  }

  static String get privacyPolicyUrl => '$legalBaseUrl/privacy';
  static String get termsOfServiceUrl => '$legalBaseUrl/terms';
  static String get accountDeletionUrl => '$legalBaseUrl/account-deletion';
  static String get communityStandardsUrl => '$legalBaseUrl/community-standards';

  /// On Android Play builds, digital Premium must not use in-app VietQR.
  /// Food/order VietQR stays allowed. Full Play Billing lands in a follow-up.
  static bool get requiresPlayBillingForPremium {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android;
  }

  /// AI chat API. Mặc định qua Gateway (`/api/v1/ai/chat` → sync-agent-service :8088).
  /// Bỏ qua Gateway khi debug: `--dart-define=AI_BASE_URL=http://<pc-lan-ip>:8088`
  static String get aiBaseUrl {
    const fromEnv = String.fromEnvironment('AI_BASE_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv.replaceAll(RegExp(r'/$'), '');
    return baseUrl;
  }

  /// `true` khi gọi thẳng sync-agent-service, không qua Gateway.
  static bool get aiUsesDirectService =>
      const String.fromEnvironment('AI_BASE_URL', defaultValue: '').isNotEmpty;

  static String get aiChatPath =>
      aiUsesDirectService ? '/ai/chat' : '/v1/ai/chat';

  static String get aiChatConfirmPath =>
      aiUsesDirectService ? '/ai/chat/confirm' : '/v1/ai/chat/confirm';

  static String get aiChatUrl => '$aiBaseUrl$aiChatPath';

  /// Web OAuth 2.0 client (Google Cloud Console → **Web application**).
  /// Used as [googleServerClientId] on Android/iOS so Google returns an ID token for IAM.
  static const String defaultGoogleWebClientId =
      '366172488368-n76f7r1ab2joffko6cvf2b3564togekv.apps.googleusercontent.com';

  /// Android OAuth client (Google Cloud Console → **Android**).
  /// Package: com.sync.sync_app + debug SHA-1 must be registered for this client.
  static const String defaultGoogleAndroidClientId =
      '366172488368-4brct5chejltaa6rlk42b0pnn2a53skr.apps.googleusercontent.com';

  /// Platform OAuth client ID passed to GoogleSignIn.initialize(clientId: ...).
  /// Android only needs [googleServerClientId] (Web client) + SHA-1 registered in Cloud Console.
  /// Override: `--dart-define=GOOGLE_CLIENT_ID=...`
  static String get googleClientId {
    const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    if (kIsWeb) return defaultGoogleWebClientId;
    return '';
  }

  /// Override: `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  /// Android/iOS: use the **Web** client ID here so Google returns an ID token IAM can verify.
  /// NOTE: `google_sign_in_web` does NOT support `serverClientId` — always return empty on Web.
  static String get googleServerClientId {
    if (kIsWeb) return ''; // google_sign_in_web asserts serverClientId == null
    const fromEnv = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;
    return defaultGoogleWebClientId;
  }
}
