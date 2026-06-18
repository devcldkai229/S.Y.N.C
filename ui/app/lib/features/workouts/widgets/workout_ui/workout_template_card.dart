import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/utils/workout_assets.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';

/// Community / system workout template card (Explore section).
class WorkoutTemplateCard extends StatefulWidget {
  const WorkoutTemplateCard({
    super.key,
    required this.workout,
    required this.onSave,
  });

  final UserCustomWorkout workout;
  final Future<bool> Function() onSave;

  @override
  State<WorkoutTemplateCard> createState() => _WorkoutTemplateCardState();
}

class _WorkoutTemplateCardState extends State<WorkoutTemplateCard> {
  bool _saving = false;
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.workout;

    return Material(
      color: WorkoutTheme.card,
      borderRadius: WorkoutTheme.radiusMd,
      child: InkWell(
        onTap: () => context.push(AppRoutes.customWorkoutDetail(w.id)),
        borderRadius: WorkoutTheme.radiusMd,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: WorkoutTheme.radiusMd,
            border: Border.all(color: WorkoutTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WorkoutCoverImage(
                assetPath: WorkoutAssets.coverForWorkout(w.workoutName),
                networkUrl: w.coverRoadmapImageUrl,
                height: 100,
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.workoutName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: WorkoutTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.fitness_center_outlined, size: 14, color: WorkoutTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('${w.exerciseCount} bài', style: _meta),
                              const SizedBox(width: 10),
                              const Icon(Icons.repeat_outlined, size: 14, color: WorkoutTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('${w.totalSets} sets', style: _meta),
                              const SizedBox(width: 10),
                              const Icon(Icons.bookmark_outline, size: 14, color: WorkoutTheme.textMuted),
                              const SizedBox(width: 4),
                              Text('${w.savesCount} lưu', style: _meta),
                            ],
                          ),
                          if (w.scheduleMode.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lịch: ${w.scheduleMode}',
                              style: const TextStyle(fontSize: 11, color: WorkoutTheme.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSaveButton(w),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _meta = TextStyle(fontSize: 12, color: WorkoutTheme.textMuted, fontWeight: FontWeight.w600);

  Widget _buildSaveButton(UserCustomWorkout w) {
    if (_saving) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
      );
    }
    if (_saved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: WorkoutTheme.lime.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 16, color: WorkoutTheme.forest),
            SizedBox(width: 4),
            Text('Đã lưu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WorkoutTheme.forest)),
          ],
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: () async {
        setState(() => _saving = true);
        final ok = await widget.onSave();
        if (!mounted) return;
        setState(() {
          _saving = false;
          if (ok) _saved = true;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Đã lưu "${w.workoutName}" vào workout của bạn' : 'Không thể lưu workout'),
            backgroundColor: ok ? AppColors.primaryGreen : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: WorkoutTheme.primary,
        side: BorderSide(color: WorkoutTheme.primary.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.bookmark_add_outlined, size: 16),
      label: const Text('Lưu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}
