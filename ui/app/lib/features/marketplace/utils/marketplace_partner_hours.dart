import 'dart:math' as math;

import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

abstract final class MarketplacePartnerHours {
  static bool isOpenNow(List<OperatingHour> hours, {DateTime? now}) {
    if (hours.isEmpty) return true;
    final time = now ?? DateTime.now();
    final day = time.weekday % 7; // API uses 0=Sunday style in seed? Check seed

    OperatingHour? today;
    for (final h in hours) {
      if (h.dayOfWeek == day) {
        today = h;
        break;
      }
    }
    today ??= hours.firstWhere(
      (h) => h.dayOfWeek == time.weekday,
      orElse: () => hours.first,
    );

    if (today.isClosed) return false;
    if (today.openTime.isEmpty || today.closeTime.isEmpty) return true;

    final current = time.hour * 60 + time.minute;
    final open = _minutes(today.openTime);
    final close = _minutes(today.closeTime);
    if (open == null || close == null) return true;
    if (close > open) return current >= open && current < close;
    return current >= open || current < close;
  }

  static String todayHoursLabel(List<OperatingHour> hours) {
    if (hours.isEmpty) return 'Mở cả ngày';
    final day = DateTime.now().weekday;
    final today = hours.cast<OperatingHour?>().firstWhere(
          (h) => h!.dayOfWeek == day,
          orElse: () => hours.isNotEmpty ? hours.first : null,
        );
    if (today == null) return 'Mở cả ngày';
    if (today.isClosed) return 'Nghỉ hôm nay';
    if (today.openTime.isEmpty) return 'Mở cả ngày';
    return '${today.openTime} – ${today.closeTime}';
  }

  static double? distanceKm({
    required double? deliveryLat,
    required double? deliveryLng,
    required PartnerLocation? partnerLocation,
  }) {
    if (deliveryLat == null || deliveryLng == null || partnerLocation == null) return null;
    return _haversine(deliveryLat, deliveryLng, partnerLocation.latitude, partnerLocation.longitude);
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((r * c).toStringAsFixed(1));
  }

  static double _deg2rad(double d) => d * math.pi / 180;

  static int? _minutes(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }
}
