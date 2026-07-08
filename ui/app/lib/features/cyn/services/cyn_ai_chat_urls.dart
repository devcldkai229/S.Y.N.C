import 'package:sync_app/core/config/app_config.dart';

/// Absolute URL for POST /ai/chat (Gateway or direct sync-agent-service).
String buildFullChatUrl() {
  if (AppConfig.aiUsesDirectService) {
    return AppConfig.aiChatUrl;
  }
  final path = AppConfig.aiChatPath;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  final base = AppConfig.baseUrl;
  final normalizedBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return '$normalizedBase$normalizedPath';
}
