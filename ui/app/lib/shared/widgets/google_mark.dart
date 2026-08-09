import 'package:flutter/material.dart';

/// Official Google "G" mark (asset from Google Identity branding).
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key, this.size = 22});

  final double size;

  static const assetPath = 'assets/images/google_g.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      filterQuality: FilterQuality.high,
      semanticLabel: 'Google',
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Colors.black,
                fontSize: size * 0.7,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
