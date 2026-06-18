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

class CommunityChallenge {
  const CommunityChallenge({
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
    this.backgroundUrl,
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
  final String? backgroundUrl;
  final String address;
  final double lat;
  final double lng;
  final String status;
  final double distanceFromUserKm;
  final ChallengeFilter filter;

  factory CommunityChallenge.fromJson(
    Map<String, dynamic> json, {
    double distanceKm = 0,
  }) {
    final goalType = _parseGoalType(json['goalType']?.toString());
    final location = json['location'];
    var lat = 0.0;
    var lng = 0.0;
    if (location is Map<String, dynamic>) {
      lat = (location['latitude'] as num?)?.toDouble() ?? 0;
      lng = (location['longitude'] as num?)?.toDouble() ?? 0;
    }

    final distance = distanceKm > 0
        ? distanceKm
        : (json['distanceKm'] as num?)?.toDouble() ?? 0;

    return CommunityChallenge(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      goalType: goalType,
      targetValue: (json['targetValue'] as num?)?.toDouble() ?? 0,
      unit: _unitFor(goalType),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      participantCount: (json['participantCount'] as num?)?.toInt() ?? 0,
      pointRewards: (json['pointRewards'] as num?)?.toInt() ?? 0,
      gifts: (json['gifts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      backgroundUrl: json['backgroundUrl']?.toString(),
      address: json['address']?.toString() ?? '',
      lat: lat,
      lng: lng,
      status: json['status']?.toString() ?? 'Active',
      distanceFromUserKm: distance,
      filter: _filterFor(goalType),
    );
  }

  LatLng get location => LatLng(lat, lng);

  bool get hasLocation => lat != 0 || lng != 0;

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

  String get homeBadge => switch (status) {
        'InProgress' => 'ĐANG DIỄN RA',
        'Upcoming' => 'SẮP DIỄN RA',
        'Active' => 'MỞ ĐĂNG KÝ',
        _ => status.toUpperCase(),
      };

  double get progressFraction {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return 1;
    final totalDays = endDate.difference(startDate).inDays;
    if (totalDays <= 0) return 0;
    final elapsed = now.difference(startDate).inDays;
    return (elapsed / totalDays).clamp(0.0, 1.0);
  }

  String get homeProgressLabel {
    if (isInProgress) {
      final totalDays = endDate.difference(startDate).inDays.clamp(1, 9999);
      final elapsed = DateTime.now().difference(startDate).inDays.clamp(0, totalDays);
      return '$elapsed/$totalDays ngày';
    }
    if (isUpcoming) return 'Sắp bắt đầu';
    if (isRegistrationOpen) return 'Đang mở đăng ký';
    return dateRangeText;
  }

  static ChallengeGoalType _parseGoalType(String? raw) => switch (raw) {
        'TotalDistance' => ChallengeGoalType.totalDistance,
        'TotalCaloriesBurned' => ChallengeGoalType.totalCaloriesBurned,
        'TotalWorkouts' => ChallengeGoalType.totalWorkouts,
        _ => ChallengeGoalType.totalWorkouts,
      };

  static String _unitFor(ChallengeGoalType goal) => switch (goal) {
        ChallengeGoalType.totalDistance => 'km',
        ChallengeGoalType.totalCaloriesBurned => 'calo',
        ChallengeGoalType.totalWorkouts => 'buổi',
      };

  static ChallengeFilter _filterFor(ChallengeGoalType goal) => switch (goal) {
        ChallengeGoalType.totalDistance => ChallengeFilter.running,
        ChallengeGoalType.totalCaloriesBurned => ChallengeFilter.calories,
        ChallengeGoalType.totalWorkouts => ChallengeFilter.workouts,
      };

  bool matchesFilter(ChallengeFilter f) {
    if (f == ChallengeFilter.all) return true;
    return filter == f;
  }
}

/// @deprecated Use [CommunityChallenge].
typedef MockChallenge = CommunityChallenge;

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
