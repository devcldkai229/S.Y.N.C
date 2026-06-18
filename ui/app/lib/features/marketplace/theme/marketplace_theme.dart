import 'package:flutter/material.dart';

/// SYNC marketplace visual tokens (sage / forest palette).
abstract final class MarketplaceTheme {
  static const primary = Color(0xFF2E6B4F);
  static const primaryDark = Color(0xFF1A3B2E);
  static const primaryMid = Color(0xFF1B4D3E);
  static const sage = Color(0xFF3D8B6E);
  static const heading = Color(0xFF1B4D3E);
  static const background = Color(0xFFF4F8F2);
  static const card = Colors.white;
  static const border = Color(0xFFE5EAE3);
  static const textMuted = Color(0xFF6B7770);
  static const limeChip = Color(0xFFDEFF9A);
  static const lightGreen = Color(0xFFDCFCE7);
  static const affiliateBg = Color(0xFFF7FBF6);
  static const affiliateBorder = Color(0xFFD4E5D8);

  static const cardRadius = 18.0;
  static const pillRadius = 999.0;

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryMid, sage],
  );

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

  static List<BoxShadow> cardShadow() => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static BoxDecoration searchDecoration() => BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      );
}
