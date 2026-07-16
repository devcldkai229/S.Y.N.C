import 'package:flutter/material.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class AiRoadmapNextSessionCard extends StatelessWidget {
  const AiRoadmapNextSessionCard({
    super.key,
    required this.session,
    required this.onStart,
    required this.onAskAi,
  });

  final RoadmapSessionOverview session;
  final VoidCallback onStart;
  final VoidCallback onAskAi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
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
    final metaParts = <String>[
      if (dateLabel.isNotEmpty) dateLabel,
      if (session.scheduledTime != null && session.scheduledTime!.isNotEmpty) session.scheduledTime!,
      if (session.durationMin > 0) l10n.aiRoadmapMetaDuration(session.durationMin),
      if (session.exerciseCount > 0) l10n.aiRoadmapMetaExercises(session.exerciseCount),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: WorkoutTheme.radiusMd,
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiRoadmapNextSession,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 8),
          Text(
            session.displayNameVi,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary),
          ),
          if (session.subtitleEn.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              session.subtitleEn,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (session.isAi)
                _badge('AI', AppColors.primaryGreen),
              _badge(intensityLabel, intensityColor),
            ],
          ),
          if (metaParts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: WorkoutTheme.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    metaParts.join(' · '),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted),
                  ),
                ),
              ],
            ),
          ],
          if (session.rationale(isVi).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.aiRoadmapSessionWhy,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.rationale(isVi),
                    style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: WorkoutTheme.textPrimary),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: onStart,
                    style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                    child: Text(l10n.aiRoadmapStart),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: onAskAi,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                    ),
                    child: Text(l10n.aiRoadmapAskAi),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );
  }
}
