import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_band_chip.dart';

class AiRoadmapReadinessGauge extends StatelessWidget {
  const AiRoadmapReadinessGauge({
    super.key,
    required this.recoveryScore,
    required this.fatigueLevel,
    required this.sorenessScore,
    this.cnsFatigueScore,
  });

  final int recoveryScore;
  final int fatigueLevel;
  final int sorenessScore;
  final int? cnsFatigueScore;

  @override
  Widget build(BuildContext context) {
    final readiness = AiRoadmapDisplayHelpers.readinessBand(recoveryScore);
    final fatigue = AiRoadmapDisplayHelpers.fatigueBand(fatigueLevel, cnsFatigueScore: cnsFatigueScore);
    final soreness = AiRoadmapDisplayHelpers.sorenessBand(sorenessScore);

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
          const Text(
            'Mức sẵn sàng hôm nay',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: WorkoutTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: readiness.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: readiness.accent.withValues(alpha: 0.25)),
            ),
            child: Text(
              readiness.label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: readiness.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (i) {
              final active = i == readiness.segment;
              Color color;
              if (i == 0) {
                color = const Color(0xFF2E6B4F);
              } else if (i == 1) {
                color = const Color(0xFFD97706);
              } else {
                color = const Color(0xFF16803A);
              }
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? color : WorkoutTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: AiRoadmapBandChip(label: 'Mức mệt mỏi', data: fatigue)),
              const SizedBox(width: 10),
              Expanded(child: AiRoadmapBandChip(label: 'Đau cơ', data: soreness)),
            ],
          ),
        ],
      ),
    );
  }
}
