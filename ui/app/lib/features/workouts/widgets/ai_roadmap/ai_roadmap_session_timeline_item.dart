import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class AiRoadmapSessionTimelineItem extends StatelessWidget {
  const AiRoadmapSessionTimelineItem({
    super.key,
    required this.session,
  });

  final RoadmapSessionOverview session;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCompleted = session.isCompleted;
    final isNext = session.isNextUp;
    final statusLabel = isCompleted
        ? l10n.aiRoadmapStatusDone
        : isNext
            ? l10n.aiRoadmapStatusNext
            : l10n.aiRoadmapStatusUpcoming;
    final intensityColor = switch (session.intensity) {
      'Light' => const Color(0xFF2E6B4F),
      'High' => const Color(0xFFB45309),
      _ => AppColors.primaryGreen,
    };
    final intensityLabel = switch (session.intensity) {
      'Light' => l10n.aiRoadmapIntensityLight,
      'High' => l10n.aiRoadmapIntensityHigh,
      _ => l10n.aiRoadmapIntensityModerate,
    };

    final dateLabel = AiRoadmapDisplayHelpers.formatSessionDate(
      session.scheduledDate,
      locale: Localizations.localeOf(context),
    );
    final meta = [
      if (dateLabel.isNotEmpty) dateLabel,
      if (session.scheduledTime != null && session.scheduledTime!.isNotEmpty) session.scheduledTime!,
      if (session.durationMin > 0) l10n.aiRoadmapMetaDuration(session.durationMin),
      intensityLabel,
      if (session.exerciseCount > 0) l10n.aiRoadmapMetaExercises(session.exerciseCount),
    ].join(' · ');

    return InkWell(
      onTap: () => context.push(AppRoutes.customSessionDetail(session.id)),
      borderRadius: WorkoutTheme.radiusMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: WorkoutTheme.card,
          borderRadius: WorkoutTheme.radiusMd,
          border: Border.all(
            color: isNext ? AppColors.primaryGreen.withValues(alpha: 0.35) : WorkoutTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: intensityColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.displayNameVi,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isCompleted ? WorkoutTheme.textMuted : WorkoutTheme.textPrimary,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isCompleted
                    ? WorkoutTheme.textMuted
                    : isNext
                        ? AppColors.primaryGreen
                        : WorkoutTheme.sage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
