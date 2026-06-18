import 'package:flutter/material.dart';

/// SYNC Workouts — sage/forest palette, card-first layout.
abstract final class WorkoutTheme {
  static const forest = Color(0xFF1B4D3E);
  static const sage = Color(0xFF2E6B4F);
  static const primary = Color(0xFF16803A);
  static const lime = Color(0xFFDEFF9A);
  static const background = Color(0xFFF4F8F2);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5EAE3);
  static const textPrimary = Color(0xFF1E293B);
  static const textMuted = Color(0xFF64748B);
  static const minTouch = 56.0;

  static BorderRadius get radiusLg => BorderRadius.circular(20);
  static BorderRadius get radiusMd => BorderRadius.circular(16);

  static List<BoxShadow> cardShadow({double opacity = 0.06}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];
}
