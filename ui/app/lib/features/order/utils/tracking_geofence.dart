import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/utils/tracking_status_mapper.dart';

/// Mirrors server geofence rules so UI status advances with live GPS.
abstract final class TrackingGeofence {
  static const pickupPickedUpRadiusM = 1000.0;
  static const dropoffArrivedRadiusM = 100.0;
  static const dropoffCompletedRadiusM = 50.0;

  static const _distance = Distance();

  static TrackingUpdate applyToUpdate({
    required TrackingSession session,
    required TrackingUpdate base,
    required double lat,
    required double lng,
  }) {
    final delivery = _advanceDeliveryStatus(
      current: base.deliveryStatus ?? 'Assigned',
      session: session,
      lat: lat,
      lng: lng,
    );

    final orderStatus = TrackingStatusMapper.displayOrderStatus(
      orderStatus: base.orderStatus,
      deliveryStatus: delivery,
    );

    return TrackingUpdate(
      orderId: base.orderId,
      orderStatus: orderStatus,
      deliveryStatus: delivery,
      shipperLat: lat,
      shipperLng: lng,
      etaMinutes: base.etaMinutes,
      shipper: base.shipper,
      statusMessage: TrackingStatusMapper.statusMessage(
        orderStatus: orderStatus,
        deliveryStatus: delivery,
        apiMessage: base.statusMessage,
      ),
      timestamp: base.timestamp,
    );
  }

  static String _advanceDeliveryStatus({
    required String current,
    required TrackingSession session,
    required double lat,
    required double lng,
  }) {
    final pickup = LatLng(session.pickupLat, session.pickupLng);
    final dropoff = LatLng(session.dropoffLat, session.dropoffLng);
    final shipper = LatLng(lat, lng);

    final distPickup =
        _distance.as(LengthUnit.Meter, shipper, pickup);
    final distDropoff =
        _distance.as(LengthUnit.Meter, shipper, dropoff);

    final next = switch (current) {
      'Pending' => current,
      'Assigned' => distPickup <= pickupPickedUpRadiusM
          ? 'PickedUp'
          : 'HeadingToPickup',
      'HeadingToPickup' || 'ArrivedAtPickup' =>
        distPickup <= pickupPickedUpRadiusM ? 'PickedUp' : current,
      'PickedUp' => distDropoff <= dropoffCompletedRadiusM
          ? 'Completed'
          : distDropoff <= dropoffArrivedRadiusM
              ? 'Arrived'
              : 'Delivering',
      'Delivering' => distDropoff <= dropoffCompletedRadiusM
          ? 'Completed'
          : distDropoff <= dropoffArrivedRadiusM
              ? 'Arrived'
              : 'Delivering',
      'Arrived' =>
        distDropoff <= dropoffCompletedRadiusM ? 'Completed' : current,
      _ => current,
    };

    return _maxRank(current, next);
  }

  static String _maxRank(String current, String candidate) {
    final currentRank = _rank(current);
    final candidateRank = _rank(candidate);
    return candidateRank >= currentRank ? candidate : current;
  }

  static int _rank(String status) => switch (status) {
        'Pending' => 0,
        'Assigned' => 1,
        'HeadingToPickup' => 2,
        'ArrivedAtPickup' => 3,
        'PickedUp' => 4,
        'Delivering' => 5,
        'Arrived' => 6,
        'Completed' => 7,
        'Cancelled' || 'Failed' => 99,
        _ => 0,
      };
}
