import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/workouts/state/roadmap_refresh_notifier.dart';

/// SignalR connection to Roadmap service for live AI schedule / roadmap updates.
class RoadmapRealtimeService {
  RoadmapRealtimeService(this._auth, this._refreshNotifier);

  final AuthService _auth;
  final RoadmapRefreshNotifier _refreshNotifier;

  HubConnection? _connection;
  bool _connecting = false;

  Future<void> start() async {
    if (_connecting) return;
    if (_connection?.state == HubConnectionState.Connected) return;

    final token = await _auth.getValidAccessToken();
    if (token == null || token.isEmpty) return;

    _connecting = true;
    try {
      await _connection?.stop();
      final hubUrl =
          '${AppConfig.roadmapHubUrl}?access_token=${Uri.encodeComponent(token)}';

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _connection!.on('RoadmapUpdated', _onRoadmapUpdated);

      _connection!.onclose(({error}) {
        if (kDebugMode && error != null) {
          debugPrint('[Roadmap SignalR] disconnected: $error');
        }
      });

      await _connection!.start();
    } catch (e) {
      if (kDebugMode) debugPrint('[Roadmap SignalR] connect failed: $e');
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

  void _onRoadmapUpdated(List<Object?>? args) {
    if (args == null || args.isEmpty) {
      _refreshNotifier.notifyUpdated();
      return;
    }
    final raw = args.first;
    String? kind;
    if (raw is Map) {
      kind = raw['kind']?.toString();
    }
    _refreshNotifier.notifyUpdated(kind: kind);
  }
}
