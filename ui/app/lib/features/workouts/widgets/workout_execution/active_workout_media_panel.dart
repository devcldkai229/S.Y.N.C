import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/exercise_media_url_resolver.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_thumbnail.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:video_player/video_player.dart';

class ActiveWorkoutMediaPanel extends StatelessWidget {
  const ActiveWorkoutMediaPanel({
    super.key,
    required this.detail,
    required this.loading,
    required this.videoController,
    required this.videoReady,
    required this.videoError,
    this.exerciseName,
    this.onFullscreen,
    this.height = 200,
  });

  final ExerciseCatalogDetail? detail;
  final bool loading;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final String? videoError;
  final String? exerciseName;
  final VoidCallback? onFullscreen;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ExecutionTheme.cardWhite,
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
      return const Center(
        child: CircularProgressIndicator(color: ExecutionTheme.syncLime, strokeWidth: 2.5),
      );
    }

    final videos = detail?.videoAssets;
    final thumb = ExerciseMediaUrlResolver.resolve(detail?.heroThumbnailUrl);
    final controller = videoController;

    if (videos != null && videos.isNotEmpty && controller != null && videoReady && videoError == null) {
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

    if (thumb != null && thumb.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: thumb,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _fallbackThumbnail(),
      );
    }

    return _fallbackThumbnail();
  }

  Widget _fallbackThumbnail() {
    final name = exerciseName ?? detail?.nameVi ?? detail?.nameEn;
    if (name != null && name.isNotEmpty) {
      return CatalogExerciseThumbnail(
        exerciseName: name,
        fill: true,
        borderRadius: 0,
      );
    }

    return Container(
      color: ExecutionTheme.inputFill,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.play_circle_outline_rounded, size: 52, color: ExecutionTheme.slateMuted),
          SizedBox(height: 8),
          Text(
            'Video hướng dẫn',
            style: TextStyle(color: ExecutionTheme.slateMuted, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
