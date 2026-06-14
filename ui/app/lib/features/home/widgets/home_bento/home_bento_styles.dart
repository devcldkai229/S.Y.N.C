import 'package:flutter/material.dart';

abstract final class HomeBentoColors {
  static const background = Color(0xFFF8F9FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textMuted = Color(0xFF6B7280);
  static const forestGreen = Color(0xFF1A3B2E);
  static const primaryGreen = Color(0xFF16803A);
  static const lightGreen = Color(0xFFDCFCE7);
  static const limeChip = Color(0xFFDEFF9A);
}

class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = HomeBentoColors.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  static BoxDecoration decoration({Color? color}) => BoxDecoration(
        color: color ?? HomeBentoColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: decoration(color: color),
      child: child,
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HomeBentoColors.textPrimary,
            ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}
