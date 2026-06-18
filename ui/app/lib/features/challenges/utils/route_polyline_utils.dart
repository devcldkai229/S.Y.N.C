import 'package:latlong2/latlong.dart';

const _distance = Distance();

/// Keeps only road-network geometry. Does not append raw GPS endpoints
/// (that would draw a straight "bird's eye" segment for off-road venues).
List<LatLng> trimOffRoadPolyline({
  required List<LatLng> polyline,
  required LatLng origin,
  required LatLng destination,
}) {
  if (polyline.length < 2) return polyline;

  var points = List<LatLng>.from(polyline);
  points = _trimConnector(points, origin, fromTail: false);
  points = _trimConnector(points, destination, fromTail: true);
  return points;
}

List<LatLng> _trimConnector(
  List<LatLng> points,
  LatLng target, {
  required bool fromTail,
  double minConnectorMeters = 25,
}) {
  while (points.length >= 2) {
    final anchorIndex = fromTail ? points.length - 2 : 1;
    final tipIndex = fromTail ? points.length - 1 : 0;

    final anchor = points[anchorIndex];
    final tip = points[tipIndex];

    final segmentM = _distance(anchor, tip);
    final tipToTargetM = _distance(tip, target);
    final anchorToTargetM = _distance(anchor, target);

    final isOffRoadConnector = segmentM >= minConnectorMeters
        && tipToTargetM < anchorToTargetM
        && segmentM >= anchorToTargetM * 0.45;

    if (!isOffRoadConnector) break;
    points.removeAt(tipIndex);
  }

  return points;
}

double offRoadGapMeters(List<LatLng> polyline, LatLng destination) {
  if (polyline.isEmpty) return 0;
  return _distance(polyline.last, destination);
}

LatLng? polylineMidpoint(List<LatLng> polyline) {
  if (polyline.length < 2) return null;

  var total = 0.0;
  for (var i = 1; i < polyline.length; i++) {
    total += _distance(polyline[i - 1], polyline[i]);
  }
  if (total <= 0) return polyline[polyline.length ~/ 2];

  final target = total / 2;
  var walked = 0.0;
  for (var i = 1; i < polyline.length; i++) {
    final seg = _distance(polyline[i - 1], polyline[i]);
    if (walked + seg >= target) {
      final t = (target - walked) / seg;
      return LatLng(
        polyline[i - 1].latitude + (polyline[i].latitude - polyline[i - 1].latitude) * t,
        polyline[i - 1].longitude + (polyline[i].longitude - polyline[i - 1].longitude) * t,
      );
    }
    walked += seg;
  }

  return polyline.last;
}
