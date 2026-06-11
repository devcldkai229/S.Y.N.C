class ShipperInfo {
  const ShipperInfo({
    required this.name,
    required this.plateNumber,
    this.phone,
  });

  final String name;
  final String plateNumber;
  final String? phone;
}

/// Unified tracking payload — mock timer and future WebSocket share this shape.
class TrackingUpdate {
  const TrackingUpdate({
    required this.orderId,
    required this.orderStatus,
    this.deliveryStatus,
    this.shipperLat,
    this.shipperLng,
    this.etaMinutes,
    this.shipper,
    this.statusMessage,
    required this.timestamp,
  });

  final String orderId;
  final String orderStatus;
  final String? deliveryStatus;
  final double? shipperLat;
  final double? shipperLng;
  final int? etaMinutes;
  final ShipperInfo? shipper;
  final String? statusMessage;
  final DateTime timestamp;

  bool get showShipperMarker =>
      shipperLat != null && shipperLng != null && const {'PickedUp', 'Delivering', 'Delivered'}.contains(orderStatus);
}

class TrackingSession {
  const TrackingSession({
    required this.orderId,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
  });

  final String orderId;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
}
