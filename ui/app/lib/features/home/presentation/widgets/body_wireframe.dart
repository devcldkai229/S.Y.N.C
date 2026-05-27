import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

/// Placeholder holographic body until Unity/3D asset is integrated.
class BodyWireframe extends StatelessWidget {
  const BodyWireframe({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BodyWireframePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _BodyWireframePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = SyncColors.cyan.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fill = Paint()
      ..color = SyncColors.cyan.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final cx = size.width * 0.5;
    final headR = size.width * 0.09;
    final headY = size.height * 0.18;

    canvas.drawCircle(Offset(cx, headY), headR, fill);
    canvas.drawCircle(Offset(cx, headY), headR, stroke);

    final torso = Path()
      ..moveTo(cx - size.width * 0.14, headY + headR + 8)
      ..lineTo(cx + size.width * 0.14, headY + headR + 8)
      ..lineTo(cx + size.width * 0.1, size.height * 0.52)
      ..lineTo(cx - size.width * 0.1, size.height * 0.52)
      ..close();
    canvas.drawPath(torso, fill);
    canvas.drawPath(torso, stroke);

    void limb(Offset from, Offset to) {
      canvas.drawLine(from, to, stroke);
    }

    final shoulderY = headY + headR + 20;
    limb(
      Offset(cx - size.width * 0.14, shoulderY),
      Offset(cx - size.width * 0.28, size.height * 0.42),
    );
    limb(
      Offset(cx + size.width * 0.14, shoulderY),
      Offset(cx + size.width * 0.28, size.height * 0.38),
    );
    limb(
      Offset(cx - size.width * 0.1, size.height * 0.52),
      Offset(cx - size.width * 0.12, size.height * 0.78),
    );
    limb(
      Offset(cx + size.width * 0.1, size.height * 0.52),
      Offset(cx + size.width * 0.18, size.height * 0.74),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
