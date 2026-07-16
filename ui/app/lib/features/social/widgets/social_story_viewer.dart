import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';
import 'package:video_player/video_player.dart';

class SocialStoryViewer extends StatefulWidget {
  const SocialStoryViewer({
    super.key,
    required this.groups,
    required this.initialGroupIndex,
    this.initialStoryIndex = 0,
    required this.onViewed,
    required this.onLike,
  });

  final List<SocialStoryFeedGroup> groups;
  final int initialGroupIndex;
  final int initialStoryIndex;
  final Future<void> Function(SocialStory story) onViewed;
  final Future<bool> Function(SocialStory story) onLike;

  /// Returns `true` when the user finished all stories (for "caught up" snackbar).
  static Future<bool?> show(
    BuildContext context, {
    required List<SocialStoryFeedGroup> groups,
    required int initialGroupIndex,
    int initialStoryIndex = 0,
    required Future<void> Function(SocialStory story) onViewed,
    required Future<bool> Function(SocialStory story) onLike,
  }) {
    final safeGroups = groups.where((g) => g.stories.isNotEmpty).toList();
    if (safeGroups.isEmpty) return Future.value(false);

    var groupIndex = initialGroupIndex.clamp(0, safeGroups.length - 1);
    // Remap index if filtering removed empty groups before the tap target.
    if (initialGroupIndex < groups.length) {
      final targetId = groups[initialGroupIndex].authorId;
      final remapped = safeGroups.indexWhere((g) => g.authorId == targetId);
      if (remapped >= 0) groupIndex = remapped;
    }

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => SocialStoryViewer(
        groups: safeGroups,
        initialGroupIndex: groupIndex,
        initialStoryIndex: initialStoryIndex,
        onViewed: onViewed,
        onLike: onLike,
      ),
    );
  }

  @override
  State<SocialStoryViewer> createState() => _SocialStoryViewerState();
}

class _SocialStoryViewerState extends State<SocialStoryViewer>
    with TickerProviderStateMixin {
  static const _imageDuration = Duration(seconds: 5);

  late int _groupIndex;
  late int _storyIndex;
  late final AnimationController _imageTimer;

  VideoPlayerController? _video;
  double _videoProgress = 0;
  bool _holding = false;
  bool _closing = false;
  int _loadGen = 0;
  final Set<String> _likedStoryIds = {};
  final Set<String> _viewedIds = {};

  SocialStoryFeedGroup get _group => widget.groups[_groupIndex];

  SocialStory get _story => _group.stories[_storyIndex];

  double get _progress {
    if (_story.isVideo) return _videoProgress.clamp(0.0, 1.0);
    return _imageTimer.value.clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _groupIndex = widget.initialGroupIndex.clamp(0, widget.groups.length - 1);
    final stories = widget.groups[_groupIndex].stories;
    _storyIndex = widget.initialStoryIndex.clamp(0, stories.length - 1);
    _imageTimer = AnimationController(vsync: this, duration: _imageDuration)
      ..addStatusListener(_onImageTimerStatus)
      ..addListener(() {
        if (mounted && !_story.isVideo) setState(() {});
      });
    WidgetsBinding.instance.addPostFrameCallback((_) => _startCurrent());
  }

  void _onImageTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_holding && !_closing) {
      _next();
    }
  }

  Future<void> _startCurrent() async {
    final gen = ++_loadGen;
    await _disposeVideo();
    if (!mounted || gen != _loadGen) return;

    _imageTimer.stop();
    _imageTimer.reset();
    _videoProgress = 0;

    final story = _story;
    _recordView(story);

    if (!mounted || gen != _loadGen) return;

    if (story.isVideo) {
      await _initVideo(story, gen);
    } else {
      if (!_holding) _imageTimer.forward(from: 0);
    }
    if (mounted && gen == _loadGen) setState(() {});
  }

  Future<void> _initVideo(SocialStory story, int gen) async {
    final url = MediaUrlResolver.resolve(story.mediaUrl) ?? story.mediaUrl;
    if (url.isEmpty) {
      if (gen == _loadGen) _next();
      return;
    }

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _video = controller;
    try {
      await controller.initialize();
      if (!mounted || gen != _loadGen || _video != controller) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(false);
      await controller.setVolume(0);
      controller.addListener(_onVideoTick);
      if (!_holding) await controller.play();
      if (mounted && gen == _loadGen) setState(() {});
    } catch (_) {
      await controller.dispose();
      if (_video == controller) _video = null;
      if (mounted && !_closing && gen == _loadGen) _next();
    }
  }

  void _onVideoTick() {
    final v = _video;
    if (v == null || !v.value.isInitialized) return;
    final duration = v.value.duration;
    final position = v.value.position;
    if (duration.inMilliseconds <= 0) return;

    final progress = position.inMilliseconds / duration.inMilliseconds;
    if (mounted) {
      setState(() => _videoProgress = progress.clamp(0.0, 1.0));
    }

    if (!_holding &&
        !_closing &&
        position >= duration - const Duration(milliseconds: 80)) {
      v.removeListener(_onVideoTick);
      _next();
    }
  }

  Future<void> _disposeVideo() async {
    final v = _video;
    _video = null;
    if (v == null) return;
    v.removeListener(_onVideoTick);
    await v.dispose();
  }

  void _recordView(SocialStory story) {
    if (_viewedIds.contains(story.id)) return;
    _viewedIds.add(story.id);
    widget.onViewed(story);
  }

  Future<void> _likeCurrent() async {
    final story = _story;
    if (_likedStoryIds.contains(story.id)) return;
    final ok = await widget.onLike(story);
    if (ok && mounted) setState(() => _likedStoryIds.add(story.id));
  }

  void _pause() {
    _holding = true;
    _imageTimer.stop();
    _video?.pause();
  }

  void _resume() {
    _holding = false;
    if (_story.isVideo) {
      _video?.play();
    } else if (_imageTimer.value < 1) {
      _imageTimer.forward();
    }
  }

  void _next() {
    if (_closing) return;
    if (_storyIndex + 1 < _group.stories.length) {
      setState(() => _storyIndex += 1);
      _startCurrent();
      return;
    }
    if (_groupIndex + 1 < widget.groups.length) {
      setState(() {
        _groupIndex += 1;
        _storyIndex = 0;
      });
      _startCurrent();
      return;
    }
    _closeEnded();
  }

  void _prev() {
    if (_closing) return;
    if (_storyIndex > 0) {
      setState(() => _storyIndex -= 1);
      _startCurrent();
      return;
    }
    if (_groupIndex > 0) {
      final prevStories = widget.groups[_groupIndex - 1].stories;
      setState(() {
        _groupIndex -= 1;
        _storyIndex = prevStories.length - 1;
      });
      _startCurrent();
    }
  }

  void _closeEnded() {
    if (_closing) return;
    _closing = true;
    _imageTimer.stop();
    Navigator.of(context).pop(true);
  }

  void _closeManual() {
    if (_closing) return;
    _closing = true;
    _imageTimer.stop();
    Navigator.of(context).pop(false);
  }

  void _onTapUp(TapUpDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    if (details.localPosition.dx < width * 0.4) {
      _prev();
    } else {
      _next();
    }
  }

  @override
  void dispose() {
    _imageTimer
      ..removeStatusListener(_onImageTimerStatus)
      ..dispose();
    final v = _video;
    _video = null;
    v?.removeListener(_onVideoTick);
    v?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final story = _story;
    final author = _group.authorSnapshot;
    final liked = _likedStoryIds.contains(story.id) || story.isLikedByMe;
    final storyCount = _group.stories.length;

    return Material(
      color: Colors.black,
      child: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: _onTapUp,
              onLongPressStart: (_) => _pause(),
              onLongPressEnd: (_) => _resume(),
              child: _StoryMedia(
                story: story,
                video: _video,
              ),
            ),
            Positioned(
              top: 8,
              left: 12,
              right: 12,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < storyCount; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          child: _ProgressSegment(
                            value: i < _storyIndex
                                ? 1
                                : i == _storyIndex
                                    ? _progress
                                    : 0,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SyncAvatar(
                        name: author.fullName,
                        imageUrl: author.avatarUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          author.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _closeManual,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (story.caption != null &&
                story.caption!.trim().isNotEmpty &&
                !story.isTextOnly)
              Positioned(
                left: 16,
                right: 16,
                bottom: 88,
                child: Text(
                  story.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
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
                      backgroundColor:
                          liked ? AppColors.primaryGreen : Colors.white24,
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

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 2.5,
        backgroundColor: Colors.white24,
        color: Colors.white,
      ),
    );
  }
}

class _StoryMedia extends StatelessWidget {
  const _StoryMedia({
    required this.story,
    required this.video,
  });

  final SocialStory story;
  final VideoPlayerController? video;

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

    if (story.isVideo) {
      final v = video;
      if (v == null || !v.value.isInitialized) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: AspectRatio(
            aspectRatio: v.value.aspectRatio == 0 ? 9 / 16 : v.value.aspectRatio,
            child: VideoPlayer(v),
          ),
        ),
      );
    }

    final url = MediaUrlResolver.resolve(story.mediaUrl) ?? story.mediaUrl;
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
      ),
    );
  }
}

/// Sort tray groups for viewer: self → unseen → seen (by latestAt desc).
List<SocialStoryFeedGroup> sortStoryGroupsForViewer(
  List<SocialStoryFeedGroup> groups, {
  required String currentUserId,
  Set<String> seenAuthorIds = const {},
}) {
  final self = <SocialStoryFeedGroup>[];
  final unseen = <SocialStoryFeedGroup>[];
  final seen = <SocialStoryFeedGroup>[];

  for (final g in groups) {
    final isSelf = currentUserId.isNotEmpty && g.authorId == currentUserId;
    final isSeen = !g.hasUnseen || seenAuthorIds.contains(g.authorId);
    if (isSelf) {
      self.add(g);
    } else if (isSeen) {
      seen.add(g);
    } else {
      unseen.add(g);
    }
  }

  int byLatest(SocialStoryFeedGroup a, SocialStoryFeedGroup b) {
    final aAt = a.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bAt = b.latestAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bAt.compareTo(aAt);
  }

  unseen.sort(byLatest);
  seen.sort(byLatest);
  return [...self, ...unseen, ...seen];
}
