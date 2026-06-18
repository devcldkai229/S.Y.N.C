import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/data/models/notification_models.dart';

/// Maintains a SignalR connection to Notification service for live in-app events.
class NotificationRealtimeService {
  NotificationRealtimeService(this._storage, this._inbox);

  final FlutterSecureStorage _storage;
  final NotificationInboxNotifier _inbox;

  HubConnection? _connection;
  bool _connecting = false;

  Future<void> start() async {
    if (_connecting) return;
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _storage.read(key: AuthInterceptor.accessTokenKey);
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      await _connection?.stop();
      final hubUrl =
          '${AppConfig.notificationHubUrl}?access_token=${Uri.encodeComponent(token)}';

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _connection!.on('NotificationReceived', _onNotificationReceived);

      _connection!.onclose(({error}) {
        if (kDebugMode && error != null) {
          debugPrint('[SignalR] disconnected: $error');
        }
      });

      await _connection!.start();
    } catch (e) {
      if (kDebugMode) debugPrint('[SignalR] connect failed: $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> stop() async {
    try {
      await _connection?.stop();
    } catch (_) {
      // ignore
    }
    _connection = null;
  }

  void _onNotificationReceived(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;

    final notification = AppNotification.fromJson(Map<String, dynamic>.from(raw));
    _inbox.onRealtimeNotification(notification);
  }
}
