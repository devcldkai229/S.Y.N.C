import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_thumbnail.dart';
import 'package:sync_app/features/workouts/widgets/exercise_detail/exercise_detail_content.dart';
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
          _error = 'Không tìm thấy bài tập.';
        });
        return;
      }
      await _inlineVideoController?.dispose();
      _inlineVideoController = null;
      _inlineVideoReady = false;

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
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      if (!mounted) return;
      setState(() => _inlineVideoReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _inlineVideoReady = false);
    }
  }

  void _onAddToWorkout() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm "${_detail?.nameVi ?? widget.preview?.nameVi ?? 'bài tập'}" vào workout'),
        backgroundColor: ExerciseCatalogTheme.slateDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onTryPractice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chế độ tập thử sẽ sớm có mặt'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFullscreen() {
    final detail = _detail;
    if (detail == null) return;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_inlineVideoController != null && _inlineVideoReady)
                Center(
                  child: AspectRatio(
                    aspectRatio: _inlineVideoController!.value.aspectRatio,
                    child: VideoPlayer(_inlineVideoController!),
                  ),
                )
              else
                Positioned.fill(
                  child: CatalogExerciseThumbnail(
                    networkUrl: detail.imageUrls.isNotEmpty
                        ? detail.imageUrls.first
                        : detail.heroThumbnailUrl,
                    exerciseName: detail.nameVi.isNotEmpty ? detail.nameVi : detail.nameEn,
                    fill: true,
                    borderRadius: 0,
                  ),
                ),
              Positioned(
                top: MediaQuery.paddingOf(ctx).top + 8,
                right: 12,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExerciseCatalogTheme.offWhite,
      extendBodyBehindAppBar: true,
      body: _buildBody(),
      bottomNavigationBar: _detail == null
          ? null
          : ExerciseDetailBottomBar(
              onAddToWorkout: _onAddToWorkout,
              onTryPractice: _onTryPractice,
            ),
    );
  }

  Widget _buildBody() {
    if (_loading && _detail == null) {
      return const Center(
        child: CircularProgressIndicator(color: ExerciseCatalogTheme.syncLime),
      );
    }
    if (_error != null && _detail == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final d = _detail;
    if (d == null) return const SizedBox.shrink();

    return RefreshIndicator(
      color: ExerciseCatalogTheme.slateDark,
      backgroundColor: ExerciseCatalogTheme.syncLime,
      onRefresh: _load,
      child: ExerciseDetailContent(
        detail: d,
        inlineController: _inlineVideoController,
        inlineReady: _inlineVideoReady,
        onFullscreen: _openFullscreen,
      ),
    );
  }
}
