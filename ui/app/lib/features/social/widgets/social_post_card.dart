import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/screens/social_image_viewer_screen.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.isLikedByMe,
    required this.isSharedByMe,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onOpenProfile,
    required this.onMoreTap,
  });

  final SocialPost post;
  final bool isLikedByMe;
  final bool isSharedByMe;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onComment;
  final void Function(String userId) onOpenProfile;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                _Avatar(
                  name: post.authorSnapshot.fullName,
                  url: post.authorSnapshot.avatarUrl,
                  onTap: () => onOpenProfile(post.authorId),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => onOpenProfile(post.authorId),
                        child: Text(
                          post.authorSnapshot.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        post.timeAgo,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onMoreTap,
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...post.mediaUrls.map((url) {
              final imageUrls = post.mediaUrls.where(SocialPostCard._isImageUrl).toList();
              return _MediaItem(
                url: url,
                imageUrls: imageUrls,
              );
            }).whereType<Widget>(),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                _ReactionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  activeIcon: Icons.thumb_up_alt_rounded,
                  label: _formatCount(post.metrics.likeCount),
                  active: isLikedByMe,
                  activeColor: AppColors.primaryGreen,
                  onTap: onLike,
                ),
                _ReactionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: _formatCount(post.metrics.commentCount),
                  active: false,
                  activeColor: AppColors.primaryGreen,
                  onTap: onComment,
                ),
                const Spacer(),
                _ShareButton(
                  label: _formatCount(post.metrics.shareCount),
                  active: isSharedByMe,
                  onTap: onShare,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  static bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, this.onTap});

  final String name;
  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatar = (url != null && url!.isNotEmpty)
        ? CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.lightGreen,
            backgroundImage: CachedNetworkImageProvider(url!),
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.lightGreen,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.primaryGreen,
              ),
            ),
          );

    return InkWell(
      borderRadius: BorderRadius.circular(200),
      onTap: onTap,
      child: avatar,
    );
  }
}

class _MediaItem extends StatelessWidget {
  const _MediaItem({
    required this.url,
    required this.imageUrls,
  });

  final String url;
  final List<String> imageUrls;

  static SocialMediaType _mediaTypeForUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.webm') || lower.endsWith('.mov')) {
      return SocialMediaType.video;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return SocialMediaType.image;
    }
    return SocialMediaType.none;
  }

  @override
  Widget build(BuildContext context) {
    final type = _mediaTypeForUrl(url);
    switch (type) {
      case SocialMediaType.image:
        final initialIndex = imageUrls.indexOf(url);
        return _ImageMedia(
          url: url,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SocialImageViewerScreen(
                  imageUrls: imageUrls,
                  initialIndex: initialIndex < 0 ? 0 : initialIndex,
                ),
              ),
            );
          },
        );
      case SocialMediaType.video:
        return _VideoMedia(videoUrl: url);
      case SocialMediaType.none:
        return const SizedBox.shrink();
    }
  }
}

class _ImageMedia extends StatelessWidget {
  const _ImageMedia({required this.url, this.onTap});

  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AppColors.lightGreen),
              errorWidget: (context, url, error) => Container(
                color: AppColors.lightGreen,
                child: const Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoMedia extends StatelessWidget {
  const _VideoMedia({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SocialVideoPlayerScreen(videoUrl: videoUrl),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.lightGreen.withValues(alpha: 0.2)),
                Container(color: Colors.black.withValues(alpha: 0.35)),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 36),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 12,
                  child: Row(
                    children: [
                      Icon(Icons.videocam_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'VIDEO',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primaryGreen : AppColors.textMuted;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ios_share_outlined, color: color, size: 22),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
