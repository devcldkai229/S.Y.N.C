import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/social/screens/social_post_media_gallery_screen.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/social/utils/social_media_utils.dart';

/// Feed media in a padded card — up to 4 tiles, "+N" overlay on the 4th when more exist.
class SocialPostMediaBlock extends StatelessWidget {
  const SocialPostMediaBlock({super.key, required this.urls});

  final List<String> urls;

  static const _maxVisible = 4;
  static const _gap = 4.0;
  static const _cardRadius = 12.0;
  static const _outerPadding = EdgeInsets.symmetric(horizontal: 12);

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
      return Padding(
        padding: _outerPadding,
        child: _MediaCard(
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: _MediaTile(
              url: urls.first,
              onTap: () => _openGallery(context),
            ),
          ),
        ),
      );
    }

    final visibleCount = urls.length > _maxVisible ? _maxVisible : urls.length;
    final extra = urls.length > _maxVisible ? urls.length - (_maxVisible - 1) : 0;

    return Padding(
      padding: _outerPadding,
      child: _MediaCard(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cellW = (constraints.maxWidth - _gap) / 2;
            final cellH = urls.length == 2 ? 160.0 : 120.0;

            if (urls.length == 2) {
              return SizedBox(
                height: cellH,
                child: Row(
                  children: [
                    Expanded(
                      child: _MediaTile(
                        url: urls[0],
                        onTap: () => _openGallery(context, initialIndex: 0),
                      ),
                    ),
                    const SizedBox(width: _gap),
                    Expanded(
                      child: _MediaTile(
                        url: urls[1],
                        onTap: () => _openGallery(context, initialIndex: 1),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Wrap(
              spacing: _gap,
              runSpacing: _gap,
              children: List.generate(visibleCount, (i) {
                final isOverlayCell = extra > 0 && i == _maxVisible - 1;
                final overlayLabel = isOverlayCell ? '+$extra' : null;
                final galleryIndex = isOverlayCell ? _maxVisible - 1 : i;

                return SizedBox(
                  width: cellW,
                  height: cellH,
                  child: _MediaTile(
                    url: urls[i],
                    overlayLabel: overlayLabel,
                    onTap: () => _openGallery(context, initialIndex: galleryIndex),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(SocialPostMediaBlock._cardRadius),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              Container(color: AppColors.lightGreen.withValues(alpha: 0.35))
            else
              CachedNetworkImage(
                imageUrl: MediaUrlResolver.resolve(url)!,
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
                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 48),
              ),
            ],
            if (overlayLabel != null)
              Container(
                color: Colors.black.withValues(alpha: 0.55),
                alignment: Alignment.center,
                child: Text(
                  overlayLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
