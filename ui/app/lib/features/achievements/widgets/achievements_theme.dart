import 'package:flutter/material.dart';

/// Vibrant premium palette for the Achievements feature.
abstract final class AchievementsTheme {
  static const background = Color(0xFFFAFAFA);
  static const card = Colors.white;
  static const slate = Color(0xFF1E293B);
  static const progress = Color(0xFF6366F1);
  static const progressEnd = Color(0xFF8B5CF6);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);

  static const inProgressGradientStart = Color(0xFF6366F1);
  static const inProgressGradientEnd = Color(0xFF8B5CF6);
  static const goldGradientStart = Color(0xFFF59E0B);
  static const goldGradientEnd = Color(0xFFD97706);

  static const chipXpBg = Color(0xFFF3F0F8);
  static const chipXpText = Color(0xFF5B4B8A);
  static const chipCoinBg = Color(0xFFF8F4EA);
  static const chipCoinText = Color(0xFF8B6914);

  static const statsPanelWidth = 300.0;
  static const panelAnimationMs = 300;

  static List<BoxShadow> cardShadow({Color tint = const Color(0xFF6366F1)}) => [
        BoxShadow(
          color: tint.withValues(alpha: 0.10),
          blurRadius: 15,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> goldCardShadow = [
    BoxShadow(
      color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
      blurRadius: 15,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}
