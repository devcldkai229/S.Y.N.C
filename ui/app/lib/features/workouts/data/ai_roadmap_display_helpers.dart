import 'package:flutter/material.dart';

/// Converts raw AI/ML scores into user-friendly Vietnamese bands (never show raw numbers in UI).
abstract final class AiRoadmapDisplayHelpers {
  static String fitnessGoalVi(String goal) {
    final g = goal.toLowerCase().replaceAll(' ', '');
    if (g.contains('fatloss') || g.contains('fat')) return 'Giảm mỡ';
    if (g.contains('musclegain') || g.contains('muscle')) return 'Tăng cơ';
    if (g.contains('recomp')) return 'Tái cấu trúc';
    if (g.contains('maintain')) return 'Duy trì';
    if (g.contains('health')) return 'Sức khỏe';
    if (g.contains('endurance') || g.contains('stamina')) return 'Tăng sức bền';
    if (goal.isEmpty) return 'Mục tiêu cá nhân';
    return goal;
  }

  static ReadinessBand readinessBand(int recoveryScore) {
    if (recoveryScore >= 70) {
      return ReadinessBand(
        label: 'Sẵn sàng 💪',
        accent: const Color(0xFF16803A),
        background: const Color(0xFFDCFCE7),
        segment: 2,
      );
    }
    if (recoveryScore >= 40) {
      return ReadinessBand(
        label: 'Bình thường',
        accent: const Color(0xFFD97706),
        background: const Color(0xFFFEF3C7),
        segment: 1,
      );
    }
    return ReadinessBand(
      label: 'Nên nghỉ ngơi',
      accent: const Color(0xFF2E6B4F),
      background: const Color(0xFFE8F5E9),
      segment: 0,
    );
  }

  /// Merges fatigueLevel + optional cnsFatigueScore into one band.
  static BandChipData fatigueBand(int fatigueLevel, {int? cnsFatigueScore}) {
    final raw = cnsFatigueScore != null ? ((fatigueLevel + cnsFatigueScore) / 2).round() : fatigueLevel;
    return _levelBand(raw, lowLabel: 'Thấp', midLabel: 'Vừa', highLabel: 'Cao');
  }

  static BandChipData sorenessBand(int muscleSorenessScore) {
    return _levelBand(muscleSorenessScore, lowLabel: 'Nhẹ', midLabel: 'Vừa', highLabel: 'Nhiều');
  }

  static BandChipData intensityBand(int energyDemandScore) {
    return _levelBand(energyDemandScore, lowLabel: 'Nhẹ', midLabel: 'Vừa', highLabel: 'Cao');
  }

  static String coachTipMessage(String recommendedIntensity) {
    final i = recommendedIntensity.toLowerCase();
    if (i.contains('low') || i.contains('light') || i.contains('nhẹ')) {
      return 'Hôm nay nên tập nhẹ nhàng, lắng nghe cơ thể nhé';
    }
    if (i.contains('high') || i.contains('cao')) {
      return 'Hôm nay có thể đẩy mạnh hơn một chút — cố gắng vừa sức nhé';
    }
    return 'Hôm nay nên tập cường độ vừa nhé';
  }

  static String sessionStatusLabel({required bool isCompleted, required bool isNextUp}) {
    if (isCompleted) return 'Đã xong ✓';
    if (isNextUp) return 'Sắp tới';
    return 'Sắp tới';
  }

  static BandChipData _levelBand(int score, {required String lowLabel, required String midLabel, required String highLabel}) {
    if (score < 35) {
      return BandChipData(label: lowLabel, accent: const Color(0xFF16803A), background: const Color(0xFFDCFCE7));
    }
    if (score < 65) {
      return BandChipData(label: midLabel, accent: const Color(0xFFD97706), background: const Color(0xFFFEF3C7));
    }
    return BandChipData(label: highLabel, accent: const Color(0xFF64748B), background: const Color(0xFFF1F5F9));
  }
}

class ReadinessBand {
  const ReadinessBand({
    required this.label,
    required this.accent,
    required this.background,
    required this.segment,
  });

  final String label;
  final Color accent;
  final Color background;
  /// 0 = rest, 1 = normal, 2 = ready
  final int segment;
}

class BandChipData {
  const BandChipData({required this.label, required this.accent, required this.background});

  final String label;
  final Color accent;
  final Color background;
}
