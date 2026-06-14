import 'package:flutter/material.dart';

/// Minimal order / tracking UI tokens — single green accent.
abstract final class OrderTheme {
  static const accent = Color(0xFF2E6B4F);
  static const background = Color(0xFFF4F8F2);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF1F2937);
  static const textMuted = Color(0xFF6B7280);
  static const line = Color(0xFFE5E7EB);
  static const radius = 16.0;

  static BoxDecoration cardDecoration() => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: line),
      );
}
