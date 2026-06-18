import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/widgets/social_create_post_sheet.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class SocialFeedCreatePostRow extends StatelessWidget {
  const SocialFeedCreatePostRow({
    super.key,
    this.user,
  });

  final SocialAuthorSnapshot? user;

  void _openComposer(BuildContext context) {
    SocialCreatePostSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          SyncAvatar(
            name: user?.fullName ?? 'Bạn',
            imageUrl: user?.avatarUrl,
            radius: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _openComposer(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AppColors.backgroundAlt,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Bạn đang nghĩ gì thế?',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          _MediaActionButton(
            icon: Icons.videocam_rounded,
            color: const Color(0xFFE53935),
            onTap: () => _openComposer(context),
          ),
          _MediaActionButton(
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF43A047),
            onTap: () => _openComposer(context),
          ),
          _MediaActionButton(
            icon: Icons.emoji_emotions_outlined,
            color: const Color(0xFFF9A825),
            onTap: () => _openComposer(context),
          ),
        ],
      ),
    );
  }
}

class _MediaActionButton extends StatelessWidget {
  const _MediaActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon, color: color, size: 24),
    );
  }
}
