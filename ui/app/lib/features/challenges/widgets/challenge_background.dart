import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/home/data/home_assets.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

/// Background layer for challenge cards (image URL or video poster fallback).
class ChallengeBackground extends StatelessWidget {
  const ChallengeBackground({
    super.key,
    this.backgroundUrl,
    this.fit = BoxFit.cover,
  });

  final String? backgroundUrl;
  final BoxFit fit;

  static bool isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.contains('/video/');
  }

  @override
  Widget build(BuildContext context) {
    final url = backgroundUrl?.trim();
    if (url == null || url.isEmpty) {
      return _assetFallback();
    }

    if (isVideoUrl(url)) {
      return Stack(
        fit: StackFit.expand,
        children: [
          _assetFallback(),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  HomeBentoColors.forestGreen.withValues(alpha: 0.85),
                  HomeBentoColors.primaryGreen.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              size: 48,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (_, __) => _assetFallback(),
      errorWidget: (_, __, ___) => _assetFallback(),
    );
  }

  Widget _assetFallback() {
    return Image.asset(
      HomeAssets.challengeCover,
      fit: fit,
      errorBuilder: (_, __, ___) => Image.asset(
        HomeAssets.challengeCoverFallback,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(color: HomeBentoColors.forestGreen),
      ),
    );
  }
}
