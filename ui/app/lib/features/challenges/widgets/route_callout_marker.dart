import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';

class RouteCalloutMarker extends StatelessWidget {
  const RouteCalloutMarker({
    super.key,
    required this.routeInfo,
    this.vehicleLabel = '🛵 Xe máy',
  });

  final TravelModeRouteInfo routeInfo;
  final String vehicleLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 168),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vehicleLabel,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${routeInfo.distanceLabel} · ${routeInfo.durationLabel}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryGreen,
                ),
              ),
              if (routeInfo.arrivalLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  routeInfo.arrivalLabel,
                  style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        ),
        CustomPaint(
          size: const Size(14, 8),
          painter: _CalloutTailPainter(),
        ),
      ],
    );
  }
}

class _CalloutTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primaryGreen.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
