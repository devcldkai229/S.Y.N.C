import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/widgets/social_create_post_sheet.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

/// Inline "create post" entry at the top of the Social feed.
class SocialCreatePostCard extends StatelessWidget {
  const SocialCreatePostCard({
    super.key,
    this.userName = 'You',
    this.avatarUrl,
  });

  final String userName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Material(
        color: AppColors.cardBackground,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => SocialCreatePostSheet.show(context),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  SyncAvatar(
                    name: userName,
                    imageUrl: avatarUrl,
                    radius: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Text(
                        "What's your workout today?",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => SocialCreatePostSheet.show(context),
                    icon: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primaryGreen,
                      size: 24,
                    ),
                    tooltip: 'Add photo',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
