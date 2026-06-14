import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';
import 'package:sync_app/features/order/utils/tracking_status_mapper.dart';

/// Real-time tracking via SignalR (Gateway) + REST fallback.
class WebSocketTrackingService implements ITrackingService {
  WebSocketTrackingService(this._auth, this._api);

  final AuthService _auth;
  final OrderRemoteDataSource _api;

  HubConnection? _connection;
  StreamController<TrackingUpdate>? _controller;
  Timer? _fallbackTimer;
  int _generation = 0;
  TrackingUpdate? _lastUpdate;

  @override
  Stream<TrackingUpdate> watch(TrackingSession session) {
    _stopInternal();
    final generation = ++_generation;
    _controller = StreamController<TrackingUpdate>.broadcast();
    _bootstrap(session, generation);
    return _controller!.stream;
  }

  Future<void> _bootstrap(TrackingSession session, int generation) async {
    await _pullFallback(session, generation);
    await _connectHub(session, generation);
    _fallbackTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (generation != _generation) return;
      _pullFallback(session, generation);
    });
  }

  Future<void> _connectHub(TrackingSession session, int generation) async {
    try {
      final token = await _auth.getValidAccessToken();
      if (token == null || token.isEmpty || generation != _generation) return;

      final hubUrl =
          '${AppConfig.orderTrackingHubUrl}?access_token=${Uri.encodeComponent(token)}';

      _connection = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _connection!.on('locationUpdate', (args) => _onLocation(args, session, generation));
      _connection!.on('LocationUpdated', (args) => _onLocation(args, session, generation));
      _connection!.on('statusUpdate', (args) => _onStatus(args, session, generation));

      await _connection!.start();
      await _connection!.invoke('JoinOrderGroup', args: [session.orderId]);
    } catch (_) {
      // REST fallback keeps the screen usable.
    }
  }

  void _onLocation(List<Object?>? args, TrackingSession session, int generation) {
    if (generation != _generation || args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);
    final update = TrackingLocationUpdate.fromJson(map);
    if (update.orderId.toLowerCase() != session.orderId.toLowerCase()) return;

    _emit(
      generation,
      (_lastUpdate ?? _baseUpdate(session)).copyWithLocation(
        lat: update.latitude,
        lng: update.longitude,
        timestamp: update.updatedAt,
      ),
    );
  }

  void _onStatus(List<Object?>? args, TrackingSession session, int generation) {
    if (generation != _generation || args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);
    final orderId = map['orderId']?.toString() ?? '';
    if (orderId.toLowerCase() != session.orderId.toLowerCase()) return;

    final deliveryStatus = map['deliveryStatus']?.toString() ?? '';
    final orderStatus = TrackingStatusMapper.displayOrderStatus(
      orderStatus: map['orderStatus']?.toString(),
      deliveryStatus: deliveryStatus,
    );
    final eta = (map['etaMinutes'] as num?)?.toInt();
    final shipperName = map['shipperName']?.toString();
    final shipperPhone = map['shipperPhone']?.toString();
    final plate = map['shipperPlateNumber']?.toString();
    final message = map['statusMessage']?.toString();
    final updatedAt = DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now();

    ShipperInfo? shipper;
    if (shipperName != null && shipperName.isNotEmpty) {
      shipper = ShipperInfo(
        name: shipperName,
        plateNumber: plate ?? '—',
        phone: shipperPhone,
      );
    }

    _emit(
      generation,
      TrackingUpdate(
        orderId: session.orderId,
        orderStatus: orderStatus,
        deliveryStatus: deliveryStatus,
        shipperLat: _lastUpdate?.shipperLat,
        shipperLng: _lastUpdate?.shipperLng,
        etaMinutes: eta ?? _lastUpdate?.etaMinutes,
        shipper: shipper ?? _lastUpdate?.shipper,
        statusMessage: message ??
            TrackingStatusMapper.statusMessage(
              orderStatus: map['orderStatus']?.toString(),
              deliveryStatus: deliveryStatus,
            ),
        timestamp: updatedAt,
      ),
    );

    if (orderStatus == 'Delivered' || orderStatus == 'Completed') {
      unawaited(stop());
    }
  }

  Future<void> _pullFallback(TrackingSession session, int generation) async {
    if (generation != _generation) return;

    try {
      await _auth.getValidAccessToken();
      final tracking = await _api.getTracking(session.orderId);
      if (tracking == null || generation != _generation) return;

      _emitFromTracking(session, tracking, generation);
    } catch (_) {}
  }

  void _emitFromTracking(
    TrackingSession session,
    DeliveryTracking tracking,
    int generation,
  ) {
    final orderStatus = TrackingStatusMapper.displayOrderStatus(
      orderStatus: tracking.orderStatus,
      deliveryStatus: tracking.status,
    );

    ShipperInfo? shipper;
    if (tracking.shipperName != null && tracking.shipperName!.isNotEmpty) {
      shipper = ShipperInfo(
        name: tracking.shipperName!,
        plateNumber: tracking.shipperPlateNumber ?? '—',
        phone: tracking.shipperPhone,
      );
    }

    final prev = _lastUpdate;
    final lat = tracking.lastKnownLat ?? prev?.shipperLat;
    final lng = tracking.lastKnownLng ?? prev?.shipperLng;

    _emit(
      generation,
      TrackingUpdate(
        orderId: session.orderId,
        orderStatus: orderStatus,
        deliveryStatus: tracking.status,
        shipperLat: lat,
        shipperLng: lng,
        etaMinutes: tracking.etaMinutes ?? _etaFromArrival(tracking.estimatedArrivalAt),
        shipper: shipper ?? prev?.shipper,
        statusMessage: TrackingStatusMapper.statusMessage(
          orderStatus: tracking.orderStatus,
          deliveryStatus: tracking.status,
          apiMessage: tracking.statusMessage,
        ),
        timestamp: tracking.lastLocationUpdatedAt ?? DateTime.now(),
      ),
    );
  }

  void _emit(int generation, TrackingUpdate update) {
    if (generation != _generation || _controller == null || _controller!.isClosed) return;
    _lastUpdate = update;
    _controller!.add(update);
  }

  TrackingUpdate _baseUpdate(TrackingSession session) => TrackingUpdate(
        orderId: session.orderId,
        orderStatus: 'Confirmed',
        timestamp: DateTime.now(),
      );

  static int? _etaFromArrival(DateTime? arrival) {
    if (arrival == null) return null;
    final minutes = arrival.difference(DateTime.now()).inMinutes;
    return minutes < 0 ? 0 : minutes;
  }

  void _stopInternal() {
    _generation++;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
    _lastUpdate = null;
    final controller = _controller;
    _controller = null;
    controller?.close();
    final connection = _connection;
    _connection = null;
    if (connection != null) {
      unawaited(connection.stop());
    }
  }

  @override
  Future<void> stop() async {
    _stopInternal();
  }
}

extension on TrackingUpdate {
  TrackingUpdate copyWithLocation({
    required double lat,
    required double lng,
    required DateTime timestamp,
  }) =>
      TrackingUpdate(
        orderId: orderId,
        orderStatus: orderStatus,
        deliveryStatus: deliveryStatus,
        shipperLat: lat,
        shipperLng: lng,
        etaMinutes: etaMinutes,
        shipper: shipper,
        statusMessage: statusMessage,
        timestamp: timestamp,
      );
}
