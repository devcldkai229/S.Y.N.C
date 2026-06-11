import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/screens/social_post_media_gallery_screen.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/social/utils/social_media_utils.dart';

/// Feed/profile media preview: 1–2 tiles visible, "+n" overlay, full gallery on tap.
class SocialPostMediaBlock extends StatelessWidget {
  const SocialPostMediaBlock({super.key, required this.urls});

  final List<String> urls;

  void _openGallery(BuildContext context, {int initialIndex = 0}) {
    if (urls.length == 1 && SocialMediaUtils.isVideoUrl(urls.first)) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SocialVideoPlayerScreen(videoUrl: urls.first),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SocialPostMediaGalleryScreen(
          urls: urls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();

    if (urls.length == 1) {
      return SizedBox(
        height: 240,
        child: _MediaTile(
          url: urls.first,
          onTap: () => _openGallery(context),
        ),
      );
    }

    if (urls.length == 2) {
      return SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(child: _MediaTile(url: urls[0], onTap: () => _openGallery(context, initialIndex: 0))),
            const SizedBox(width: 2),
            Expanded(child: _MediaTile(url: urls[1], onTap: () => _openGallery(context, initialIndex: 1))),
          ],
        ),
      );
    }

    final hidden = urls.length - 2;
    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: _MediaTile(url: urls[0], onTap: () => _openGallery(context, initialIndex: 0)),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: _MediaTile(
              url: urls[1],
              overlayLabel: '+$hidden',
              onTap: () => _openGallery(context, initialIndex: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.url,
    required this.onTap,
    this.overlayLabel,
  });

  final String url;
  final VoidCallback onTap;
  final String? overlayLabel;

  @override
  Widget build(BuildContext context) {
    final isVideo = SocialMediaUtils.isVideoUrl(url);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isVideo)
            Container(color: AppColors.lightGreen.withValues(alpha: 0.35))
          else
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.lightGreen),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.lightGreen,
                child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
              ),
            ),
          if (isVideo) ...[
            Container(color: Colors.black.withValues(alpha: 0.25)),
            const Center(
              child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 52),
            ),
          ],
          if (overlayLabel != null)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: Text(
                overlayLabel!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
