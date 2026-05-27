import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

/// Cyan perspective grid behind the 3D body hero.
class PerspectiveGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SyncColors.cyan.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    const horizonY = 0.42;
    final horizon = size.height * horizonY;
    const verticalLines = 14;
    const horizontalLines = 10;

    for (var i = 0; i <= verticalLines; i++) {
      final t = i / verticalLines;
      final topX = size.width * (0.5 + (t - 0.5) * 0.35);
      final bottomX = size.width * (0.5 + (t - 0.5) * 1.1);
      canvas.drawLine(Offset(topX, horizon), Offset(bottomX, size.height), paint);
    }

    for (var j = 0; j <= horizontalLines; j++) {
      final t = j / horizontalLines;
      final y = horizon + (size.height - horizon) * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
