import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';

class ChallengeRoute {
  const ChallengeRoute({
    required this.car,
    required this.motorbike,
    required this.walking,
  });

  final TravelModeRouteInfo car;
  final TravelModeRouteInfo motorbike;
  final TravelModeRouteInfo walking;

  factory ChallengeRoute.fromJson(Map<String, dynamic> json) {
    return ChallengeRoute(
      car: TravelModeRouteInfo.fromJson(json['car'] as Map<String, dynamic>? ?? const {}),
      motorbike: TravelModeRouteInfo.fromJson(json['motorbike'] as Map<String, dynamic>? ?? const {}),
      walking: TravelModeRouteInfo.fromJson(json['walking'] as Map<String, dynamic>? ?? const {}),
    );
  }

  TravelModeRouteInfo forMode(TravelMode mode) => switch (mode) {
        TravelMode.car => car,
        TravelMode.motorbike => motorbike,
        TravelMode.walking => walking,
      };
}

class TravelModeRouteInfo {
  const TravelModeRouteInfo({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.polyline,
    this.estimatedArrivalAt,
    this.offRoadGapMeters = 0,
  });

  final double distanceKm;
  final int estimatedMinutes;
  final List<LatLng> polyline;
  final DateTime? estimatedArrivalAt;

  /// Meters from road-snapped route end to the challenge GPS pin.
  final double offRoadGapMeters;

  factory TravelModeRouteInfo.fromJson(Map<String, dynamic> json) {
    final rawPolyline = json['polyline'];
    final points = <LatLng>[];
    if (rawPolyline is List) {
      for (final item in rawPolyline) {
        if (item is Map<String, dynamic>) {
          final lat = (item['latitude'] as num?)?.toDouble();
          final lng = (item['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            points.add(LatLng(lat, lng));
          }
        }
      }
    }

    DateTime? arrivalAt;
    final rawArrival = json['estimatedArrivalAt'];
    if (rawArrival is String && rawArrival.isNotEmpty) {
      arrivalAt = DateTime.tryParse(rawArrival)?.toLocal();
    }

    return TravelModeRouteInfo(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 0,
      polyline: points,
      estimatedArrivalAt: arrivalAt,
      offRoadGapMeters: (json['offRoadGapMeters'] as num?)?.toDouble() ?? 0,
    );
  }

  String get offRoadGapLabel {
    if (offRoadGapMeters < 30) return '';
    if (offRoadGapMeters >= 1000) {
      return 'Còn ~${(offRoadGapMeters / 1000).toStringAsFixed(1)} km đi bộ đến điểm gặp';
    }
    return 'Còn ~${offRoadGapMeters.round()} m đi bộ đến điểm gặp';
  }

  String get distanceLabel {
    if (distanceKm >= 10) return '${distanceKm.round()} km';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String get durationLabel => '$estimatedMinutes phút';

  String get arrivalLabel {
    if (estimatedArrivalAt == null) return '';
    return 'Đến lúc ${DateFormat('HH:mm').format(estimatedArrivalAt!)}';
  }
}
