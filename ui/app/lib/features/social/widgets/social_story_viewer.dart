import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';

class SocialStoryViewer extends StatefulWidget {
  const SocialStoryViewer({
    super.key,
    required this.group,
    required this.onViewed,
    required this.onLike,
  });

  final SocialStoryFeedGroup group;
  final Future<void> Function(SocialStory story) onViewed;
  final Future<bool> Function(SocialStory story) onLike;

  static Future<void> show(
    BuildContext context, {
    required SocialStoryFeedGroup group,
    required Future<void> Function(SocialStory story) onViewed,
    required Future<bool> Function(SocialStory story) onLike,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => SocialStoryViewer(
        group: group,
        onViewed: onViewed,
        onLike: onLike,
      ),
    );
  }

  @override
  State<SocialStoryViewer> createState() => _SocialStoryViewerState();
}

class _SocialStoryViewerState extends State<SocialStoryViewer> {
  late final PageController _pageController;
  late int _index;
  final Set<String> _likedStoryIds = {};

  List<SocialStory> get _stories => widget.group.stories;

  @override
  void initState() {
    super.initState();
    _index = 0;
    _pageController = PageController();
    _recordView(_stories.first);
  }

  Future<void> _recordView(SocialStory story) async {
    await widget.onViewed(story);
  }

  Future<void> _likeCurrent() async {
    final story = _stories[_index];
    if (_likedStoryIds.contains(story.id)) return;
    final ok = await widget.onLike(story);
    if (ok && mounted) setState(() => _likedStoryIds.add(story.id));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _stories[_index];
    final liked = _likedStoryIds.contains(story.id) || story.isLikedByMe;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _stories.length,
              onPageChanged: (i) {
                setState(() => _index = i);
                _recordView(_stories[i]);
              },
              itemBuilder: (context, index) {
                final s = _stories[index];
                return _StoryPage(story: s);
              },
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.group.authorSnapshot.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filled(
                    onPressed: _likeCurrent,
                    style: IconButton.styleFrom(
                      backgroundColor: liked ? AppColors.primaryGreen : Colors.white24,
                    ),
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({required this.story});

  final SocialStory story;

  @override
  Widget build(BuildContext context) {
    if (story.isTextOnly) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF16803A), Color(0xFF22C55E)],
          ),
        ),
        child: Text(
          story.caption ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: story.mediaUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
      ),
    );
  }
}
