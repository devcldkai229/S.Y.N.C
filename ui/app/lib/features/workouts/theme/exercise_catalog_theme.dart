import 'package:flutter/material.dart';

/// Premium exercise catalog palette — Nike Training Club × SYNC lime accent.
abstract final class ExerciseCatalogTheme {
  static const syncLime = Color(0xFFDEFF9A);
  static const offWhite = Color(0xFFF8F7F4);
  static const slateDark = Color(0xFF1E293B);
  static const slateMuted = Color(0xFF64748B);
  static const slateLight = Color(0xFF94A3B8);
  static const cardWhite = Color(0xFFFFFFFF);
  static const borderSoft = Color(0xFFE2E8F0);
  static const warningOrange = Color(0xFFF97316);
  static const dangerRed = Color(0xFFEF4444);
  static const beginnerGreen = Color(0xFF16A34A);
  static const intermediateAmber = Color(0xFFF59E0B);

  static BoxShadow get softShadow => BoxShadow(
        color: slateDark.withValues(alpha: 0.06),
        blurRadius: 20,
        offset: const Offset(0, 8),
      );

  static BoxDecoration frostedCard({double radius = 16}) => BoxDecoration(
        color: cardWhite.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderSoft.withValues(alpha: 0.8)),
        boxShadow: [softShadow],
      );
}
