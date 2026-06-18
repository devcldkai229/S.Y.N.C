import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/utils/workout_assets.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:video_player/video_player.dart';

/// Demo media with fallback chain: video → network thumb/gif → local gif → brand placeholder.
class ExerciseDemoPanel extends StatelessWidget {
  const ExerciseDemoPanel({
    super.key,
    required this.exerciseName,
    this.detail,
    this.loading = false,
    this.videoController,
    this.videoReady = false,
    this.videoError,
    this.onFullscreen,
    this.height = 220,
  });

  final String exerciseName;
  final ExerciseCatalogDetail? detail;
  final bool loading;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final String? videoError;
  final VoidCallback? onFullscreen;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ExecutionTheme.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ExecutionTheme.border),
        boxShadow: [
          BoxShadow(
            color: ExecutionTheme.slateDark.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: ExecutionTheme.syncLime, strokeWidth: 2.5));
    }

    final controller = videoController;
    final videos = detail?.videoAssets;
    if (videos != null && videos.isNotEmpty && controller != null && videoReady && videoError == null) {
      return _videoStack(controller);
    }

    final heroThumb = detail?.heroThumbnailUrl;
    if (heroThumb != null && heroThumb.isNotEmpty) {
      return _networkImage(heroThumb);
    }

    final localGif = WorkoutAssets.localGifForExercise(exerciseName);
    if (localGif != null) {
      return Image.asset(
        localGif,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _brandPlaceholder(),
      );
    }

    return _brandPlaceholder();
  }

  Widget _videoStack(VideoPlayerController controller) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        if (onFullscreen != null)
          Positioned(
            right: 10,
            bottom: 10,
            child: Material(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onFullscreen,
                borderRadius: BorderRadius.circular(20),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.fullscreen_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _networkImage(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: height,
      placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: ExecutionTheme.syncLime, strokeWidth: 2)),
      errorWidget: (_, __, ___) => _brandPlaceholder(),
    );
  }

  Widget _brandPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ExecutionTheme.syncLime.withValues(alpha: 0.35),
            ExecutionTheme.inputFill,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: ExecutionTheme.syncLime.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_circle_fill_rounded, size: 40, color: ExecutionTheme.slateDark),
          ),
          const SizedBox(height: 10),
          Text(
            exerciseName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: ExecutionTheme.slateMuted),
          ),
        ],
      ),
    );
  }
}
