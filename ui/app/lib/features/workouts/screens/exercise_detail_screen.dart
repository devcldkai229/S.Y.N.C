import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:video_player/video_player.dart';

class ExerciseDetailScreen extends StatefulWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.preview,
  });

  final String exerciseId;
  final ExerciseCatalogItem? preview;

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();

  ExerciseCatalogDetail? _detail;
  bool _loading = true;
  String? _error;

  VideoPlayerController? _inlineVideoController;
  bool _inlineVideoReady = false;
  String? _inlineVideoError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inlineVideoController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _repository.getExerciseDetail(widget.exerciseId);
      if (!mounted) return;
      if (detail == null) {
        setState(() {
          _loading = false;
          _error = 'Exercise not found.';
        });
        return;
      }
      await _inlineVideoController?.dispose();
      _inlineVideoController = null;
      _inlineVideoReady = false;
      _inlineVideoError = null;

      setState(() {
        _detail = detail;
        _loading = false;
      });
      await _initInlineVideo(detail);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mapApiError(e);
      });
    }
  }

  Future<void> _initInlineVideo(ExerciseCatalogDetail detail) async {
    final videos = detail.videoAssets;
    if (videos.isEmpty) return;

    final url = videos.first.resourceUrl;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _inlineVideoController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _inlineVideoReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _inlineVideoError = e.toString());
    }
  }

  String get _title => _detail?.nameEn ?? widget.preview?.nameEn ?? 'Exercise';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _detail == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }
    if (_error != null && _detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final d = _detail;
    if (d == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
        children: [
          _MediaSection(
            detail: d,
            inlineController: _inlineVideoController,
            inlineReady: _inlineVideoReady,
            inlineError: _inlineVideoError,
            onOpenFullscreenVideo: (url) => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SocialVideoPlayerScreen(videoUrl: url),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.nameEn,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                if (d.nameVi.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(d.nameVi, style: const TextStyle(color: AppColors.textMuted, fontSize: 15)),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _DetailTag(d.exerciseCode),
                    _DetailTag(d.category),
                    _DetailTag(d.difficulty),
                    _DetailTag(d.movementPattern),
                    if (d.bodyRegion.isNotEmpty) _DetailTag(d.bodyRegion),
                    _DetailTag('${d.metValue} MET'),
                    if (d.isCompound) const _DetailTag('Compound'),
                    if (d.requiresSpotter) const _DetailTag('Spotter'),
                  ],
                ),
                const SizedBox(height: 16),
                _StatsRow(detail: d),
                if (d.primaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionTitle('Primary muscles'),
                  _BulletText(d.primaryMuscles.join(', ')),
                ],
                if (d.secondaryMuscles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Secondary muscles'),
                  _BulletText(d.secondaryMuscles.join(', ')),
                ],
                if (d.equipmentRequired.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Equipment'),
                  _BulletText(d.equipmentRequired.join(', ')),
                ],
                if (d.recommendedGoals.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Recommended goals'),
                  _BulletText(d.recommendedGoals.join(', ')),
                ],
                if (d.contraindications.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Contraindications'),
                  ...d.contraindications.map((c) => _BulletText('• $c')),
                ],
                if (d.aiCoachingCues.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('AI coaching'),
                  ...d.aiCoachingCues.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(child: Text(c, style: const TextStyle(fontSize: 14))),
                        ],
                      ),
                    ),
                  ),
                ],
                if (d.commonMistakes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const _SectionTitle('Common mistakes'),
                  ...d.commonMistakes.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $m', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                    ),
                  ),
                ],
                if (d.imageAssets.length > 1) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('Images'),
                  const SizedBox(height: 8),
                  _ImageGallery(assets: d.imageAssets),
                ],
                if (d.videoAssets.length > 1) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle('More videos'),
                  ...d.videoAssets.skip(1).map(
                        (asset) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.play_circle_outline, color: AppColors.primaryGreen),
                          title: Text('Video (${asset.animationDurationSeconds}s)'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SocialVideoPlayerScreen(videoUrl: asset.resourceUrl),
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.detail,
    required this.inlineController,
    required this.inlineReady,
    required this.inlineError,
    required this.onOpenFullscreenVideo,
  });

  final ExerciseCatalogDetail detail;
  final VideoPlayerController? inlineController;
  final bool inlineReady;
  final String? inlineError;
  final void Function(String url) onOpenFullscreenVideo;

  @override
  Widget build(BuildContext context) {
    final videos = detail.videoAssets;
    final heroThumb = detail.heroThumbnailUrl;

    if (videos.isNotEmpty && inlineController != null) {
      return _VideoHero(
        controller: inlineController!,
        ready: inlineReady,
        error: inlineError,
        thumbnailUrl: heroThumb,
        onFullscreen: () => onOpenFullscreenVideo(videos.first.resourceUrl),
      );
    }

    if (heroThumb != null) {
      return _ImageHero(imageUrl: heroThumb);
    }

    return Container(
      height: 200,
      width: double.infinity,
      color: AppColors.primaryGreen.withValues(alpha: 0.12),
      child: const Icon(Icons.fitness_center, size: 72, color: AppColors.primaryGreen),
    );
  }
}

class _VideoHero extends StatefulWidget {
  const _VideoHero({
    required this.controller,
    required this.ready,
    required this.error,
    required this.onFullscreen,
    this.thumbnailUrl,
  });

  final VideoPlayerController controller;
  final bool ready;
  final String? error;
  final String? thumbnailUrl;
  final VoidCallback onFullscreen;

  @override
  State<_VideoHero> createState() => _VideoHeroState();
}

class _VideoHeroState extends State<_VideoHero> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: widget.ready && controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: widget.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Video unavailable.\nUse fullscreen to retry.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  )
                : !widget.ready
                    ? widget.thumbnailUrl != null
                        ? CachedNetworkImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : VideoPlayer(controller),
          ),
        ),
        if (widget.ready)
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: [
                _OverlayButton(
                  icon: controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: () {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  },
                ),
                const SizedBox(width: 8),
                _OverlayButton(icon: Icons.fullscreen, onTap: widget.onFullscreen),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => ColoredBox(
          color: AppColors.lightGreen.withValues(alpha: 0.3),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => ColoredBox(
          color: AppColors.backgroundAlt,
          child: const Icon(Icons.broken_image_outlined, size: 48),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.assets});

  final List<ExerciseMotionAsset> assets;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final url = assets[index].resourceUrl;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => const ColoredBox(
              color: AppColors.backgroundAlt,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.detail});

  final ExerciseCatalogDetail detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard('Calories', '~${detail.estimatedCaloriesPerMinute}/min')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard('Rest', '${detail.recommendedRestSeconds}s')),
        const SizedBox(width: 10),
        Expanded(child: _StatCard('MET', '${detail.metValue}')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800));
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary));
  }
}

class _DetailTag extends StatelessWidget {
  const _DetailTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
