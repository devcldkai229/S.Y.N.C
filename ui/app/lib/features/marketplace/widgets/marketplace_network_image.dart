import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_asset_image.dart';

/// Loads marketplace images from assets, gateway media proxy, or external URLs.
class MarketplaceNetworkImage extends StatelessWidget {
  const MarketplaceNetworkImage({
    super.key,
    this.imageUrl,
    this.assetFallback = MarketplaceCatalog.dishPlaceholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.label,
  });

  final String? imageUrl;
  final String assetFallback;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final raw = imageUrl?.trim();

    Widget child;
    if (raw == null || raw.isEmpty || raw.startsWith('assets/')) {
      child = MarketplaceAssetImage(
        assetPath: raw?.startsWith('assets/') == true ? raw! : assetFallback,
        width: width,
        height: height,
        fit: fit,
        label: label,
      );
    } else {
      final resolved = MediaUrlResolver.resolve(raw) ?? raw;
      child = CachedNetworkImage(
        imageUrl: resolved,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (_, __, ___) => MarketplaceAssetImage(
          assetPath: assetFallback,
          width: width,
          height: height,
          fit: fit,
          label: label,
        ),
      );
    }

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}
