import 'package:flutter/material.dart';

class MarketplaceWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 28);
    path.quadraticBezierTo(size.width * 0.25, size.height, size.width * 0.5, size.height - 14);
    path.quadraticBezierTo(size.width * 0.75, size.height - 28, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
