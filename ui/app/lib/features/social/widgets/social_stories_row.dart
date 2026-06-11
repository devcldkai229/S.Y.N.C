import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/shared/utils/random_avatar_url.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

/// Facebook-style story ring colors.
abstract final class _StoryColors {
  static const unseenRing = Color(0xFF1877F2);
  static const createButton = Color(0xFF1877F2);
}

/// Fixed height for each story tile (image + label).
const _kStoryTileHeight = 168.0;
const _kStoryTileWidth = 100.0;

class SocialStoriesRow extends StatelessWidget {
  const SocialStoriesRow({
    super.key,
    required this.currentUser,
    this.storyGroups = const [],
    this.myStories = const [],
    this.seenAuthorIds = const {},
    this.onCreateStory,
    this.onStoryTap,
  });

  final SocialAuthorSnapshot? currentUser;
  final List<SocialStoryFeedGroup> storyGroups;
  final List<SocialStory> myStories;
  final Set<String> seenAuthorIds;
  final VoidCallback? onCreateStory;
  final void Function(SocialStoryFeedGroup group)? onStoryTap;

  void _showStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
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
      child: SizedBox(
        height: _kStoryTileHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: storyGroups.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _CreateStoryCard(
                user: currentUser,
                myStories: myStories,
                onTap: onCreateStory ?? () => _showStub(context),
              );
            }

            final group = storyGroups[index - 1];
            final isSeen = seenAuthorIds.contains(group.authorId);
            return _StoryCard(
              group: group,
              isSeen: isSeen,
              onTap: () {
                if (onStoryTap != null) {
                  onStoryTap!(group);
                } else {
                  _showStub(context);
                }
              },
            );
          },
        ),
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({
    required this.user,
    required this.myStories,
    required this.onTap,
  });

  final SocialAuthorSnapshot? user;
  final List<SocialStory> myStories;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewStory = myStories.isNotEmpty
        ? myStories.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b)
        : null;

    final avatarUrl = user?.avatarUrl;
    final fullName = user?.fullName ?? 'Bạn';
    final previewUrl = previewStory?.isTextOnly == true ? null : previewStory?.mediaUrl;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _kStoryTileWidth,
        height: _kStoryTileHeight,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildPreview(
                        previewUrl: previewUrl,
                        avatarUrl: avatarUrl,
                        fullName: fullName,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -10,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: _StoryColors.createButton,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tạo tin',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview({
    required String? previewUrl,
    required String? avatarUrl,
    required String fullName,
  }) {
    if (previewUrl != null && previewUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: previewUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.lightGreen),
        errorWidget: (_, __, ___) => Container(color: AppColors.lightGreen),
      );
    }

    final seed = RandomAvatarUrl.extractSeed(avatarUrl);
    if (seed != null) {
      return RandomAvatar(seed, height: _kStoryTileHeight, width: _kStoryTileWidth);
    }

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarUrl,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AppColors.lightGreen),
        errorWidget: (_, __, ___) => Container(color: AppColors.lightGreen),
      );
    }

    return Container(
      color: AppColors.lightGreen,
      child: Center(
        child: Text(
          fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryGreen,
          ),
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.group,
    required this.isSeen,
    required this.onTap,
  });

  final SocialStoryFeedGroup group;
  final bool isSeen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final story = group.previewStory;
    final ringColor = isSeen ? AppColors.borderLight : _StoryColors.unseenRing;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _kStoryTileWidth,
        height: _kStoryTileHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (story == null || story.isTextOnly)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF16803A), Color(0xFF22C55E)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.format_quote_rounded, color: Colors.white70, size: 36),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: story.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppColors.lightGreen),
                  errorWidget: (_, __, ___) => Container(color: AppColors.lightGreen),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: SyncAvatar(
                    name: group.authorSnapshot.fullName,
                    imageUrl: group.authorSnapshot.avatarUrl,
                    radius: 18,
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  group.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
