import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/order/utils/tracking_status_mapper.dart';

abstract final class TrackingMapCoords {
  static bool isValid(LatLng point) =>
      point.latitude.abs() > 0.01 &&
      point.longitude.abs() > 0.01 &&
      point.latitude.abs() <= 90 &&
      point.longitude.abs() <= 180;

  static LatLng sanitize(LatLng point, LatLng fallback) =>
      isValid(point) ? point : fallback;

  /// Demo driver start offset (~1 km south-west of pickup).
  static LatLng demoDriverStart(LatLng pickup) =>
      LatLng(pickup.latitude - 0.009, pickup.longitude - 0.009);

  static LatLng? resolveShipper({
    required LatLng pickup,
    double? lat,
    double? lng,
    String? deliveryStatus,
  }) {
    if (lat != null && lng != null) {
      final point = LatLng(lat, lng);
      if (isValid(point)) return point;
    }

    if (deliveryStatus != null &&
        TrackingStatusMapper.isActiveDelivery(deliveryStatus)) {
      return demoDriverStart(pickup);
    }

    return null;
  }
}
