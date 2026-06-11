import 'package:flutter/material.dart';

/// SYNC nutrition / marketplace visual tokens (onboarding design system).
abstract final class NutritionTheme {
  static const primary = Color(0xFF2E6B4F);
  static const heading = Color(0xFF1B4D3E);
  static const background = Color(0xFFF4F8F2);
  static const card = Colors.white;
  static const border = Color(0xFFE5EAE3);
  static const textMuted = Color(0xFF6B7770);
  static const amberSoft = Color(0xFFF5A623);
  static const amberBg = Color(0xFFFFF4E0);
  static const protein = Color(0xFF5B8DEF);
  static const carb = Color(0xFFE8A838);
  static const fat = Color(0xFF9B6FC9);
  static const water = Color(0xFF4BA3C7);

  static const cardRadius = 18.0;
  static const pillRadius = 999.0;

  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? card,
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      );
}
