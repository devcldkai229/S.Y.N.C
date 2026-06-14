import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import 'package:sync_app/features/nutrition/state/nutrition_refresh_notifier.dart';

/// SignalR connection to Nutrition service for live macro/diary updates.
class NutritionRealtimeService {
  NutritionRealtimeService(this._storage, this._refreshNotifier);

  final FlutterSecureStorage _storage;
  final NutritionRefreshNotifier _refreshNotifier;

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
          '${AppConfig.nutritionHubUrl}?access_token=${Uri.encodeComponent(token)}';

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _connection!.on('NutritionUpdated', _onNutritionUpdated);

      _connection!.onclose(({error}) {
        if (kDebugMode && error != null) {
          debugPrint('[Nutrition SignalR] disconnected: $error');
        }
      });

      await _connection!.start();
    } catch (e) {
      if (kDebugMode) debugPrint('[Nutrition SignalR] connect failed: $e');
    } finally {
      _connecting = false;
    }
  }

  Future<void> stop() async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
  }

  void _onNutritionUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;

    final dateStr = raw['date']?.toString();
    if (dateStr == null || dateStr.isEmpty) {
      _refreshNotifier.notifyDateChanged(DateTime.now());
      return;
    }

    final parsed = DateTime.tryParse(dateStr);
    _refreshNotifier.notifyDateChanged(parsed ?? DateTime.now());
  }
}
