import 'package:flutter/material.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_band_chip.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';

class AiRoadmapReadinessGauge extends StatelessWidget {
  const AiRoadmapReadinessGauge({super.key, required this.readiness});

  final RoadmapReadinessOverview readiness;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final levelLabel = switch (readiness.level) {
      'Ready' => l10n.aiRoadmapReadinessReady,
      'Rest' => l10n.aiRoadmapReadinessRest,
      _ => l10n.aiRoadmapReadinessModerate,
    };
    final segment = switch (readiness.level) {
      'Ready' => 2,
      'Rest' => 0,
      _ => 1,
    };
    final accent = switch (readiness.level) {
      'Ready' => const Color(0xFF16803A),
      'Rest' => const Color(0xFFD97706),
      _ => const Color(0xFF2E6B4F),
    };
    final fatigue = AiRoadmapDisplayHelpers.fatigueBand(readiness.fatigue);
    final soreness = AiRoadmapDisplayHelpers.sorenessBand(readiness.soreness);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: WorkoutTheme.card,
        borderRadius: WorkoutTheme.radiusMd,
        border: Border.all(color: WorkoutTheme.border),
        boxShadow: WorkoutTheme.cardShadow(opacity: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.aiRoadmapReadinessTitle,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: WorkoutTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              levelLabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: accent),
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: l10n.aiRoadmapFatigueToReady,
            child: Row(
              children: List.generate(3, (i) {
                final active = i == segment;
                final color = i == 0
                    ? const Color(0xFFD97706)
                    : i == 1
                        ? const Color(0xFF2E6B4F)
                        : const Color(0xFF16803A);
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? color : WorkoutTheme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.aiRoadmapFatigueToReady,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: WorkoutTheme.textMuted),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: AiRoadmapBandChip(label: l10n.aiRoadmapFatigueChip, data: fatigue)),
              const SizedBox(width: 10),
              Expanded(child: AiRoadmapBandChip(label: l10n.aiRoadmapSorenessChip, data: soreness)),
            ],
          ),
          if (readiness.aiNote(isVi).isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 18, color: WorkoutTheme.primary.withValues(alpha: 0.9)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    readiness.aiNote(isVi),
                    style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: WorkoutTheme.textPrimary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
