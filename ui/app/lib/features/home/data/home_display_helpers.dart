import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';

abstract final class HomeDisplayHelpers {
  static const xpPerLevel = 2000;

  static String timeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  static String fitnessGoalVi(String? goal) {
    if (goal == null || goal.isEmpty) return 'Giảm cân';
    return AiRoadmapDisplayHelpers.fitnessGoalVi(goal);
  }

  static String phaseVi(String? phase) {
    if (phase == null || phase.isEmpty) return 'Nền tảng';
    final lower = phase.toLowerCase();
    if (lower.contains('foundation')) return 'Nền tảng';
    if (lower.contains('build')) return 'Xây dựng';
    if (lower.contains('peak')) return 'Đỉnh cao';
    if (lower.contains('deload')) return 'Phục hồi';
    if (lower.contains('strength')) return 'Sức mạnh';
    if (lower.contains('hypertrophy')) return 'Tăng cơ';
    if (lower.contains('cut') || lower.contains('fat')) return 'Giảm mỡ';
    return phase;
  }

  static String weekLabelVi(int week, int totalWeeks) => 'Tuần $week / $totalWeeks';

  static String progressHintVi(double progress) {
    if (progress >= 0.5) return 'Tiến độ tốt — giữ nhịp đều đặn!';
    if (progress > 0) return 'Đang đi đúng hướng — tiếp tục nhé!';
    return 'Bắt đầu buổi đầu tiên để mở khóa giai đoạn mới.';
  }

  static String recoveryHintVi(int? score, String? recommendedIntensity) {
    if (score != null && score >= 70) return 'Cơ thể sẵn sàng cho buổi tập hôm nay.';
    if (recommendedIntensity != null && recommendedIntensity.isNotEmpty) {
      return AiRoadmapDisplayHelpers.coachTipMessage(recommendedIntensity);
    }
    return 'Lắng nghe cơ thể và tập vừa sức hôm nay.';
  }

  static String intensityLabel(int bars) {
    return switch (bars) {
      >= 4 => 'Cao',
      3 => 'Khá cao',
      2 => 'Trung bình',
      _ => 'Nhẹ',
    };
  }

  static String durationLabel(String? meta, int? minutes) {
    if (minutes != null && minutes > 0) return '$minutes phút';
    if (meta == null || meta.isEmpty) return '40 phút';
    final match = RegExp(r'(\d+)\s*Min', caseSensitive: false).firstMatch(meta);
    if (match != null) return '${match.group(1)} phút';
    return meta;
  }

  static String subscriptionTierVi(String tier) {
    if (tier.isEmpty) return 'Free';
    final lower = tier.toLowerCase();
    if (lower == 'free') return 'Free';
    if (lower == 'premium') return 'Premium';
    if (lower == 'pro') return 'Pro';
    return tier;
  }

  static double? estimateStartWeight({
    required double? current,
    required double? target,
    required double progress,
  }) {
    if (current == null || target == null) return null;
    if (progress <= 0 || progress >= 1) return current + (current - target).abs().clamp(1, 8);
    return (current - target * progress) / (1 - progress);
  }

  static String weightLabel(double? kg) {
    if (kg == null) return '—';
    final rounded = kg.roundToDouble() == kg ? kg.toInt() : kg;
    return '${rounded}kg';
  }
}
