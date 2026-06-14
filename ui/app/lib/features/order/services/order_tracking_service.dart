import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/network/auth_interceptor.dart';
import 'package:sync_app/features/order/models/order_models.dart';

class OrderTrackingService {
  OrderTrackingService(this._storage);

  final FlutterSecureStorage _storage;
  HubConnection? _connection;
  final _locationController = StreamController<TrackingLocationUpdate>.broadcast();

  Stream<TrackingLocationUpdate> get locations => _locationController.stream;

  Future<void> connect(String orderId) async {
    await disconnect();
    final token = await _storage.read(key: AuthInterceptor.accessTokenKey);
    if (token == null || token.isEmpty) return;

    final hubUrl =
        '${AppConfig.orderTrackingHubUrl}?access_token=${Uri.encodeComponent(token)}';

    _connection = HubConnectionBuilder()
        .withUrl(hubUrl)
        .withAutomaticReconnect()
        .build();

    _connection!.on('LocationUpdated', (args) {
      if (args == null || args.isEmpty) return;
      final raw = args.first;
      if (raw is! Map) return;
      final update = TrackingLocationUpdate.fromJson(Map<String, dynamic>.from(raw));
      if (update.orderId == orderId) {
        _locationController.add(update);
      }
    });

    await _connection!.start();
    await _connection!.invoke('JoinOrderGroup', args: [orderId]);
  }

  Future<void> disconnect() async {
    try {
      await _connection?.stop();
    } catch (_) {}
    _connection = null;
  }

  void dispose() {
    disconnect();
    _locationController.close();
  }
}
