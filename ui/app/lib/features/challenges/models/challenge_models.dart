import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/theme/app_colors.dart';

enum ChallengeGoalType {
  totalDistance,
  totalWorkouts,
  totalCaloriesBurned,
}

enum ChallengeFilter {
  all,
  running,
  cycling,
  calories,
  workouts,
}

enum TravelMode { car, motorbike, walking }

class MockChallenge {
  const MockChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.targetValue,
    required this.unit,
    required this.startDate,
    required this.endDate,
    required this.participantCount,
    required this.pointRewards,
    required this.gifts,
    required this.address,
    required this.lat,
    required this.lng,
    required this.status,
    required this.distanceFromUserKm,
    required this.filter,
  });

  final String id;
  final String title;
  final String description;
  final ChallengeGoalType goalType;
  final double targetValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final int participantCount;
  final int pointRewards;
  final List<String> gifts;
  final String address;
  final double lat;
  final double lng;
  final String status;
  final double distanceFromUserKm;
  final ChallengeFilter filter;

  LatLng get location => LatLng(lat, lng);

  String get dateRangeText {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    return '${fmt(startDate)} – ${fmt(endDate)}';
  }

  String get goalLabel => switch (goalType) {
        ChallengeGoalType.totalDistance => 'Chạy bộ',
        ChallengeGoalType.totalWorkouts => filter == ChallengeFilter.cycling ? 'Đạp xe' : 'Tập luyện',
        ChallengeGoalType.totalCaloriesBurned => 'Đốt calo',
      };

  String get goalEmoji => switch (goalType) {
        ChallengeGoalType.totalDistance => '🏃',
        ChallengeGoalType.totalWorkouts =>
          filter == ChallengeFilter.cycling ? '🚴' : '💪',
        ChallengeGoalType.totalCaloriesBurned => '🔥',
      };

  String get targetLabel {
    if (goalType == ChallengeGoalType.totalCaloriesBurned) {
      return '${targetValue.toInt()} $unit';
    }
    if (targetValue == targetValue.roundToDouble()) {
      return '${targetValue.toInt()} $unit';
    }
    return '$targetValue $unit';
  }

  String get goalSummary => '$goalEmoji $goalLabel tổng cộng $targetLabel';

  Color get goalColor => switch (goalType) {
        ChallengeGoalType.totalDistance => AppColors.primaryGreen,
        ChallengeGoalType.totalWorkouts => const Color(0xFF2563EB),
        ChallengeGoalType.totalCaloriesBurned => const Color(0xFFEA580C),
      };

  bool get isRegistrationOpen => status == 'Active';

  bool get isUpcoming => status == 'Upcoming';

  bool get isInProgress => status == 'InProgress';

  bool get canPreviewRoute => isRegistrationOpen || isUpcoming || isInProgress;

  String get statusLabel => switch (status) {
        'Active' => '🟢 Mở đăng ký',
        'Upcoming' => '🟡 Sắp diễn ra',
        'InProgress' => '🔵 Đang diễn ra',
        'Completed' => '✅ Đã kết thúc',
        _ => status,
      };
}

extension TravelModeX on TravelMode {
  String get label => switch (this) {
        TravelMode.car => 'Ô tô',
        TravelMode.motorbike => 'Xe máy',
        TravelMode.walking => 'Đi bộ',
      };

  String get emoji => switch (this) {
        TravelMode.car => '🚗',
        TravelMode.motorbike => '🛵',
        TravelMode.walking => '🚶',
      };
}

class MockRouteInfo {
  const MockRouteInfo({
    required this.distanceKm,
    required this.durationMinutes,
  });

  final String distanceKm;
  final String durationMinutes;
}

MockRouteInfo mockRouteInfoFor(TravelMode mode) => switch (mode) {
      TravelMode.car => const MockRouteInfo(distanceKm: '4.2 km', durationMinutes: '12 phút'),
      TravelMode.motorbike => const MockRouteInfo(distanceKm: '4.2 km', durationMinutes: '8 phút'),
      TravelMode.walking => const MockRouteInfo(distanceKm: '4.2 km', durationMinutes: '35 phút'),
    };

List<LatLng> mockRoutePolyline({
  required LatLng from,
  required LatLng to,
}) {
  return [
    from,
    LatLng(from.latitude + (to.latitude - from.latitude) * 0.25, from.longitude + (to.longitude - from.longitude) * 0.15),
    LatLng(from.latitude + (to.latitude - from.latitude) * 0.55, from.longitude + (to.longitude - from.longitude) * 0.45),
    LatLng(from.latitude + (to.latitude - from.latitude) * 0.78, from.longitude + (to.longitude - from.longitude) * 0.72),
    to,
  ];
}
