import 'package:flutter/material.dart';

/// Labeled map pin for order tracking (restaurant / user / driver).
class TrackingMapPin extends StatelessWidget {
  const TrackingMapPin({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class TrackingMapMarkerStyle {
  static const restaurantColor = Color(0xFF2E6B4F);
  static const userColor = Color(0xFFDC2626);
  static const driverColor = Color(0xFF2563EB);

  static const restaurantLabel = 'Quán ăn';
  static const userLabel = 'Bạn';
  static const driverLabel = 'Tài xế';
}
