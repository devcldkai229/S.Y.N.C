import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/active_workout_media_panel.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/active_workout_sets_table.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:video_player/video_player.dart';

/// Single exercise page inside the active-workout PageView.
class FocusExercisePage extends StatelessWidget {
  const FocusExercisePage({
    super.key,
    required this.block,
    required this.exerciseIndex,
    required this.exerciseTotal,
    required this.activeSetIndex,
    required this.completedSets,
    required this.weightControllers,
    required this.repsControllers,
    required this.previousLabel,
    required this.onSetDone,
    this.detail,
    this.loadingDetail = false,
    this.videoController,
    this.videoReady = false,
    this.videoError,
    this.onFullscreen,
    this.isCurrentPage = false,
    this.subtitle,
  });

  final SessionExecutionBlock block;
  final int exerciseIndex;
  final int exerciseTotal;
  final int activeSetIndex;
  final List<bool> completedSets;
  final List<TextEditingController> weightControllers;
  final List<TextEditingController> repsControllers;
  final String Function(int setIndex) previousLabel;
  final void Function(int setIndex) onSetDone;
  final ExerciseCatalogDetail? detail;
  final bool loadingDetail;
  final VideoPlayerController? videoController;
  final bool videoReady;
  final String? videoError;
  final VoidCallback? onFullscreen;
  final bool isCurrentPage;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final setRows = List<SetRowData>.generate(block.targetSets, (i) {
      final isActive = isCurrentPage && i == activeSetIndex && !completedSets[i];
      final isFuture = isCurrentPage && i > activeSetIndex && !completedSets[i];

      return SetRowData(
        setNumber: i + 1,
        previousLabel: previousLabel(i),
        weightController: weightControllers[i],
        repsController: repsControllers[i],
        completed: completedSets[i],
        isActive: isActive,
        isFuture: isFuture,
        onToggleDone: isActive ? () => onSetDone(i) : null,
      );
    });

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        ActiveWorkoutMediaPanel(
          detail: detail,
          loading: loadingDetail && isCurrentPage,
          exerciseName: block.exerciseName,
          videoController: isCurrentPage ? videoController : null,
          videoReady: isCurrentPage && videoReady,
          videoError: isCurrentPage ? videoError : null,
          onFullscreen: isCurrentPage ? onFullscreen : null,
          height: 200,
        ),
        const SizedBox(height: 20),
        Text(
          block.exerciseName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: ExecutionTheme.slateDark,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle ?? '${block.targetSets} Sets',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ExecutionTheme.slateMuted,
          ),
        ),
        const SizedBox(height: 20),
        ActiveWorkoutSetsTable(rows: setRows),
      ],
    );
  }
}
