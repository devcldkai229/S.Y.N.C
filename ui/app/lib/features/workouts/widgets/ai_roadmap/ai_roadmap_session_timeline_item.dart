import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
enum AiRoadmapSessionVisual { completed, nextUp, upcoming }

class AiRoadmapSessionTimelineItem extends StatelessWidget {
  const AiRoadmapSessionTimelineItem({
    super.key,
    required this.entry,
    required this.visual,
    this.animationDelay = Duration.zero,
  });

  final AiRoadmapSessionEntry entry;
  final AiRoadmapSessionVisual visual;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    final session = entry.session;
    final intensity = AiRoadmapDisplayHelpers.intensityBand(entry.energyDemandScore);
    final statusLabel = AiRoadmapDisplayHelpers.sessionStatusLabel(
      isCompleted: visual == AiRoadmapSessionVisual.completed,
      isNextUp: visual == AiRoadmapSessionVisual.nextUp,
    );

    final meta = [
      '${session.estimatedDurationMinutes} phút',
      intensity.label,
      if (session.exerciseCount > 0) '${session.exerciseCount} bài',
      if (session.scheduledTime.isNotEmpty) session.scheduledTime,
    ].join(' · ');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: visual == AiRoadmapSessionVisual.nextUp
              ? AppColors.primaryGreen.withValues(alpha: 0.1)
              : WorkoutTheme.card,
          borderRadius: WorkoutTheme.radiusMd,
          border: Border.all(
            color: visual == AiRoadmapSessionVisual.nextUp
                ? AppColors.primaryGreen.withValues(alpha: 0.45)
                : WorkoutTheme.border,
            width: visual == AiRoadmapSessionVisual.nextUp ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (visual == AiRoadmapSessionVisual.nextUp)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'TIẾP THEO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.primaryGreen),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (session.aiGenerated)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: WorkoutTheme.lime.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: WorkoutTheme.forest)),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: visual == AiRoadmapSessionVisual.completed
                                  ? WorkoutTheme.border.withValues(alpha: 0.6)
                                  : intensity.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: visual == AiRoadmapSessionVisual.completed ? WorkoutTheme.textMuted : intensity.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.sessionTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: visual == AiRoadmapSessionVisual.completed ? WorkoutTheme.textMuted : WorkoutTheme.textPrimary,
                          decoration: visual == AiRoadmapSessionVisual.completed ? TextDecoration.lineThrough : null,
                          decorationColor: WorkoutTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(meta, style: const TextStyle(fontSize: 12, color: WorkoutTheme.textMuted, height: 1.3)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Cường độ: ', style: TextStyle(fontSize: 11, color: WorkoutTheme.textMuted.withValues(alpha: 0.9))),
                          Text(intensity.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: intensity.accent)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (visual == AiRoadmapSessionVisual.nextUp) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => context.push(AppRoutes.customSessionDetail(session.id)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      minimumSize: const Size(88, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Bắt đầu', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
