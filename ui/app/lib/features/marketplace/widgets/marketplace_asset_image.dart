import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

/// Local asset with gradient fallback when file is not bundled yet.
class MarketplaceAssetImage extends StatelessWidget {
  const MarketplaceAssetImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.label,
  });

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final child = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => _Fallback(
        width: width,
        height: height,
        label: label,
      ),
    );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.width, this.height, this.label});

  final double? width;
  final double? height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MarketplaceTheme.primary.withValues(alpha: 0.35),
            MarketplaceTheme.primary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: label != null
          ? Text(
              label!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: MarketplaceTheme.heading,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            )
          : null,
    );
  }
}
