import 'package:flutter/material.dart';

/// SYNC cyber-dark palette (home shell & navigation).
abstract final class SyncColors {
  static const background = Color(0xFF070B10);
  static const surface = Color(0xFF111820);
  static const surfaceElevated = Color(0xFF1A2330);

  static const cyan = Color(0xFF2DE2E6);
  static const cyanDim = Color(0x992DE2E6);
  static const lime = Color(0xFFB4FF39);

  static const textPrimary = Color(0xFFE8F4F8);
  static const textMuted = Color(0xFF7A8B99);
  static const iconMuted = Color(0xFF5C6B78);

  static const glassFill = Color(0x66101820);
  static const glassBorder = Color(0x332DE2E6);

  static List<BoxShadow> cyanGlow({double blur = 24, double spread = 0}) => [
        BoxShadow(
          color: cyan.withValues(alpha: 0.45),
          blurRadius: blur,
          spreadRadius: spread,
        ),
      ];
}
