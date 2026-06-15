import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';
import 'package:sync_app/features/order/utils/tracking_geofence.dart';
import 'package:sync_app/features/order/utils/tracking_map_coords.dart';
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
    _fallbackTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (generation != _generation) return;
      if (_connection?.state == HubConnectionState.Connected) return;
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
      _connection!.on('statusUpdate', (args) => _onStatus(args, session, generation));

      _connection!.onclose(({error}) {
        _log('Disconnected${error != null ? ': $error' : ''}');
      });

      _connection!.onreconnecting(({error}) {
        _log('Reconnecting${error != null ? ': $error' : ''}');
      });

      _connection!.onreconnected(({connectionId}) {
        _log('Reconnected (connectionId=$connectionId)');
        unawaited(_joinOrderGroup(session, generation));
      });

      await _connection!.start();
      _log('Connected to ${AppConfig.orderTrackingHubUrl}');
      await _joinOrderGroup(session, generation);
    } catch (e) {
      _log('Hub connect failed: $e');
    }
  }

  Future<void> _joinOrderGroup(TrackingSession session, int generation) async {
    if (generation != _generation || _connection?.state != HubConnectionState.Connected) return;

    try {
      await _connection!.invoke('JoinOrderGroup', args: [session.orderId]);
      _log('JoinOrderGroup OK for order ${session.orderId}');
    } catch (e) {
      _log('JoinOrderGroup failed for order ${session.orderId}: $e');
    }
  }

  void _onLocation(List<Object?>? args, TrackingSession session, int generation) {
    if (generation != _generation || args == null || args.isEmpty) return;
    final raw = args.first;
    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);
    final update = TrackingLocationUpdate.fromJson(map);
    if (update.orderId.toLowerCase() != session.orderId.toLowerCase()) return;

    final base = (_lastUpdate ?? _baseUpdate(session)).copyWithLocation(
      lat: update.latitude,
      lng: update.longitude,
      timestamp: update.updatedAt,
    );

    _emit(
      generation,
      TrackingGeofence.applyToUpdate(
        session: session,
        base: base,
        lat: update.latitude,
        lng: update.longitude,
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

    _log('statusUpdate orderStatus=$orderStatus deliveryStatus=$deliveryStatus');

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
    } catch (e) {
      _log('REST tracking fallback failed: $e');
    }
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

    final base = TrackingUpdate(
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
    );

    if (lat != null && lng != null) {
      _emit(
        generation,
        TrackingGeofence.applyToUpdate(
          session: session,
          base: base,
          lat: lat,
          lng: lng,
        ),
      );
      return;
    }

    _emit(generation, base);
  }

  void _emit(int generation, TrackingUpdate update) {
    if (generation != _generation || _controller == null || _controller!.isClosed) return;

    final prev = _lastUpdate;
    if (prev != null &&
        prev.orderStatus == update.orderStatus &&
        prev.deliveryStatus == update.deliveryStatus &&
        prev.statusMessage == update.statusMessage &&
        prev.etaMinutes == update.etaMinutes &&
        TrackingMapCoords.sameLatLngValues(
          prev.shipperLat,
          prev.shipperLng,
          update.shipperLat,
          update.shipperLng,
        )) {
      return;
    }

    _lastUpdate = update;
    if (update.shipperLat != null && update.shipperLng != null) {
      _log('shipper → lat=${update.shipperLat} lng=${update.shipperLng}');
    }
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

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[OrderTracking SignalR] $message');
    }
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
