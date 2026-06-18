import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.remaining,
    required this.consumed,
    required this.target,
    required this.isOver,
    this.size = 180,
  });

  final int remaining;
  final int consumed;
  final int target;
  final bool isOver;
  final double size;

  @override
  Widget build(BuildContext context) {
    final progress = target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);
    final ringColor = isOver ? NutritionTheme.amberSoft : NutritionTheme.primary;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(value: value, color: ringColor, isOver: isOver),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isOver ? '${remaining.abs()}' : '$remaining',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: isOver ? NutritionTheme.amberSoft : NutritionTheme.heading,
                    ),
                  ),
                  Text(
                    isOver ? 'kcal vượt nhẹ' : 'kcal còn lại',
                    style: const TextStyle(
                      fontSize: 13,
                      color: NutritionTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.value, required this.color, required this.isOver});

  final double value;
  final Color color;
  final bool isOver;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 14.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;
    final bg = Paint()
      ..color = NutritionTheme.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bg);
    final sweep = 2 * math.pi * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
    if (isOver) {
      final over = Paint()
        ..color = NutritionTheme.amberBg
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius + 6, over);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.color != color;
}
