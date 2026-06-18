import 'dart:async';
import 'dart:math' as math;

import 'package:sync_app/features/order/config/mock_tracking_config.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';

/// Simulates Lalamove webhook ticks via [Timer.periodic].
class MockTrackingService implements ITrackingService {
  Timer? _timer;
  StreamController<TrackingUpdate>? _controller;
  TrackingSession? _session;
  int _tick = 0;
  DateTime _startedAt = DateTime.now();
  int _generation = 0;

  static const _shipper = ShipperInfo(
    name: MockTrackingConfig.shipperName,
    plateNumber: MockTrackingConfig.shipperPlate,
    phone: MockTrackingConfig.shipperPhone,
  );

  @override
  Stream<TrackingUpdate> watch(TrackingSession session) {
    _invalidate();
    final generation = _generation;
    _cancelActive();

    _session = session;
    _tick = 0;
    _startedAt = DateTime.now();
    _controller = StreamController<TrackingUpdate>.broadcast();

    _publish(generation, _buildUpdate(session, 0));

    _timer = Timer.periodic(MockTrackingConfig.tickInterval, (_) {
      if (!_isCurrent(generation)) return;

      _tick++;
      final update = _buildUpdate(session, _tick);
      _publish(generation, update);

      if (update.orderStatus == 'Delivered') {
        _timer?.cancel();
        _timer = null;
      }
    });

    return _controller!.stream;
  }

  bool _isCurrent(int generation) =>
      generation == _generation && _session != null && _controller != null && !_controller!.isClosed;

  void _publish(int generation, TrackingUpdate update) {
    if (!_isCurrent(generation)) return;
    _controller!.add(update);
  }

  void _invalidate() => _generation++;

  void _cancelActive() {
    _timer?.cancel();
    _timer = null;
    _session = null;
    _tick = 0;
    final controller = _controller;
    _controller = null;
    controller?.close();
  }

  TrackingUpdate _buildUpdate(TrackingSession session, int tick) {
    final ts = _startedAt.add(Duration(seconds: tick * MockTrackingConfig.tickInterval.inSeconds));

    if (tick <= 1) {
      return TrackingUpdate(
        orderId: session.orderId,
        orderStatus: 'Confirmed',
        deliveryStatus: 'ORDER_CONFIRMED',
        etaMinutes: 15,
        statusMessage: 'Đơn hàng đã được xác nhận',
        timestamp: ts,
      );
    }

    if (tick <= 5) {
      return TrackingUpdate(
        orderId: session.orderId,
        orderStatus: 'Preparing',
        deliveryStatus: 'PREPARING',
        etaMinutes: 15,
        statusMessage: 'Bếp đang chuẩn bị món của bạn',
        timestamp: ts,
      );
    }

    if (tick <= 7) {
      return TrackingUpdate(
        orderId: session.orderId,
        orderStatus: 'PickedUp',
        deliveryStatus: 'PICKED_UP',
        shipperLat: session.pickupLat,
        shipperLng: session.pickupLng,
        etaMinutes: 14,
        shipper: _shipper,
        statusMessage: 'Shipper đã lấy hàng tại bếp',
        timestamp: ts,
      );
    }

    if (tick <= 22) {
      final progress = (tick - 8) / (22 - 8);
      final step = (progress * (MockTrackingConfig.interpolationSteps - 1)).round();
      final pos = _interpolate(
        session.pickupLat,
        session.pickupLng,
        session.dropoffLat,
        session.dropoffLng,
        step / (MockTrackingConfig.interpolationSteps - 1),
      );
      final eta = math.max(1, (15 * (1 - progress)).round());

      return TrackingUpdate(
        orderId: session.orderId,
        orderStatus: 'Delivering',
        deliveryStatus: 'ON_GOING',
        shipperLat: pos.$1,
        shipperLng: pos.$2,
        etaMinutes: eta,
        shipper: _shipper,
        statusMessage: 'Shipper đang trên đường giao đến bạn',
        timestamp: ts,
      );
    }

    return TrackingUpdate(
      orderId: session.orderId,
      orderStatus: 'Delivered',
      deliveryStatus: 'DELIVERED',
      shipperLat: session.dropoffLat,
      shipperLng: session.dropoffLng,
      etaMinutes: 0,
      shipper: _shipper,
      statusMessage: 'Đã giao thành công',
      timestamp: ts,
    );
  }

  (double, double) _interpolate(double lat1, double lng1, double lat2, double lng2, double t) {
    return (
      lat1 + (lat2 - lat1) * t,
      lng1 + (lng2 - lng1) * t,
    );
  }

  @override
  Future<void> stop() async {
    _invalidate();
    _cancelActive();
  }
}
