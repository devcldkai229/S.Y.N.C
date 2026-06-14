import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/widgets/social_post_media_block.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class SocialFeedPostCard extends StatefulWidget {
  const SocialFeedPostCard({
    super.key,
    required this.post,
    required this.isLiked,
    required this.onLike,
    this.onOpenProfile,
    this.onComment,
    this.onShare,
    this.onDismiss,
  });

  final SocialPost post;
  final bool isLiked;
  final VoidCallback onLike;
  final void Function(String userId)? onOpenProfile;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onDismiss;

  @override
  State<SocialFeedPostCard> createState() => _SocialFeedPostCardState();
}

class _SocialFeedPostCardState extends State<SocialFeedPostCard> {
  bool _expanded = false;

  void _stubAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final badge = post.badgeLabel;
    final emoji = post.badgeEmoji;
    final openProfile = widget.onOpenProfile;
    final canOpenProfile = openProfile != null && post.authorId.isNotEmpty;

    void openAuthorProfile() {
      if (!canOpenProfile) return;
      openProfile(post.authorId);
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SyncAvatar(
                  name: post.authorSnapshot.fullName,
                  imageUrl: post.authorSnapshot.avatarUrl,
                  radius: 22,
                  onTap: canOpenProfile ? openAuthorProfile : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: canOpenProfile ? openAuthorProfile : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          post.authorSnapshot.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (badge != null && emoji != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '$emoji $badge',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        '${post.timeAgoVi} · 🌍',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _stubAction,
                  icon: const Icon(Icons.more_horiz, color: AppColors.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  onPressed: widget.onDismiss ?? _stubAction,
                  icon: const Icon(Icons.close, color: AppColors.textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _ExpandableText(
                text: post.content,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
            ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SocialPostMediaBlock(urls: post.mediaUrls),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: _MetricsRow(
                likes: post.metrics.likeCount,
                comments: post.metrics.commentCount,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: AppColors.borderLight),
          _ActionBar(
            isLiked: widget.isLiked,
            onLike: widget.onLike,
            onComment: widget.onComment ?? _stubAction,
            onShare: widget.onShare ?? _stubAction,
          ),
        ],
      ),
    );
  }
}

class _ExpandableText extends StatelessWidget {
  const _ExpandableText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  final String text;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = const TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.textPrimary,
        );
        final span = TextSpan(text: text, style: style);
        final tp = TextPainter(
          text: span,
          maxLines: 3,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final exceeds = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: style,
              maxLines: expanded ? null : 3,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (exceeds && !expanded)
              GestureDetector(
                onTap: onToggle,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Xem thêm',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.likes,
    required this.comments,
  });

  final int likes;
  final int comments;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (likes > 0) ...[
          const Icon(Icons.thumb_up_alt_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            '$likes',
            style: _metricStyle,
          ),
          const SizedBox(width: 12),
        ],
        if (comments > 0) ...[
          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text('$comments', style: _metricStyle),
        ],
      ],
    );
  }

  static const _metricStyle = TextStyle(
    fontSize: 12,
    color: AppColors.textMuted,
    fontWeight: FontWeight.w500,
  );
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: isLiked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_outlined,
              label: 'Thích',
              color: isLiked ? const Color(0xFF1877F2) : AppColors.textSecondary,
              onTap: onLike,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Bình luận',
              onTap: onComment,
            ),
          ),
          Expanded(
            child: _ActionButton(
              icon: Icons.ios_share_rounded,
              label: 'Chia sẻ',
              onTap: onShare,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
