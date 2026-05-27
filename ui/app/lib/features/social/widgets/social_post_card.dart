import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';

class SocialPostCard extends StatelessWidget {
  const SocialPostCard({
    super.key,
    required this.post,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
  });

  final SocialPost post;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;

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
                _Avatar(name: post.authorName, url: post.authorAvatarUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textPrimary,
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
                  onPressed: () {},
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
          if (post.mediaType == SocialMediaType.image && post.imageUrl != null) ...[
            const SizedBox(height: 12),
            _ImageMedia(url: post.imageUrl!),
          ],
          if (post.mediaType == SocialMediaType.video &&
              (post.videoThumbnailUrl != null || post.videoUrl != null)) ...[
            const SizedBox(height: 12),
            _VideoMedia(
              thumbnailUrl: post.videoThumbnailUrl ?? post.videoUrl!,
              videoUrl: post.videoUrl,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Row(
              children: [
                _ReactionButton(
                  icon: Icons.thumb_up_alt_outlined,
                  activeIcon: Icons.thumb_up_alt_rounded,
                  label: _formatCount(post.likeCount),
                  active: post.isLikedByMe,
                  activeColor: AppColors.primaryGreen,
                  onTap: onLike,
                ),
                _ReactionButton(
                  icon: Icons.thumb_down_alt_outlined,
                  activeIcon: Icons.thumb_down_alt_rounded,
                  label: _formatCount(post.dislikeCount),
                  active: post.isDislikedByMe,
                  activeColor: Colors.red.shade400,
                  onTap: onDislike,
                ),
                _ReactionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: _formatCount(post.commentCount),
                  active: false,
                  activeColor: AppColors.primaryGreen,
                  onTap: onComment,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border, color: AppColors.textMuted),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.ios_share_outlined, color: AppColors.textMuted, size: 22),
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
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url});

  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (url != null && url!.isNotEmpty) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.lightGreen,
        backgroundImage: CachedNetworkImageProvider(url!),
      );
    }
    return CircleAvatar(
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
  }
}

class _ImageMedia extends StatelessWidget {
  const _ImageMedia({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.lightGreen),
            errorWidget: (_, __, ___) => Container(
              color: AppColors.lightGreen,
              child: const Icon(Icons.broken_image_outlined, size: 48),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoMedia extends StatelessWidget {
  const _VideoMedia({required this.thumbnailUrl, this.videoUrl});

  final String thumbnailUrl;
  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () {
          if (videoUrl == null) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SocialVideoPlayerScreen(videoUrl: videoUrl!),
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
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.lightGreen),
                ),
                Container(color: Colors.black.withValues(alpha: 0.25)),
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
