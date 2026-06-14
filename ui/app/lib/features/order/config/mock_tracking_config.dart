/// Demo Lalamove-style tracking coordinates and timing.
/// SWAP: production uses backend-provided pickup/dropoff — not this file.
abstract final class MockTrackingConfig {
  static const pickupLat = 10.8428503;
  static const pickupLng = 106.7794253;
  static const pickupLabel = 'Bếp SYNC Fit';

  /// ~2.5 km from kitchen when GPS denied.
  static const fallbackDropLat = 10.8650;
  static const fallbackDropLng = 106.8020;
  static const fallbackDropLabel = 'Quận 2, TP.HCM';

  static const tickInterval = Duration(seconds: 2);
  static const interpolationSteps = 30;

  static const demoActiveOrderId = 'demo-active-1';

  static const shipperName = 'Nguyễn Văn Minh';
  static const shipperPlate = '59-H1 123.45';
  static const shipperPhone = '0901234567';
}
