import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class AiRoadmapPhaseCard extends StatelessWidget {
  const AiRoadmapPhaseCard({
    super.key,
    required this.phaseTitle,
    required this.currentWeek,
    required this.totalWeeks,
    required this.fitnessGoal,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.progressPercent,
  });

  final String phaseTitle;
  final int currentWeek;
  final int totalWeeks;
  final String fitnessGoal;
  final double currentWeightKg;
  final double targetWeightKg;
  final int progressPercent;

  @override
  Widget build(BuildContext context) {
    final goalVi = AiRoadmapDisplayHelpers.fitnessGoalVi(fitnessGoal);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WorkoutTheme.primary.withValues(alpha: 0.14),
            WorkoutTheme.lime.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: WorkoutTheme.radiusLg,
        border: Border.all(color: WorkoutTheme.primary.withValues(alpha: 0.18)),
        boxShadow: WorkoutTheme.cardShadow(opacity: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GIAI ĐOẠN HIỆN TẠI',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: WorkoutTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Text(phaseTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
                const SizedBox(height: 6),
                Text('Tuần $currentWeek/$totalWeeks', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WorkoutTheme.sage)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: WorkoutTheme.card.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(goalVi, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WorkoutTheme.primary)),
                    ),
                  ],
                ),
                if (targetWeightKg > 0) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${currentWeightKg.toStringAsFixed(1)} → ${targetWeightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: WorkoutTheme.forest),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AnimatedProgressRing(percent: progressPercent),
        ],
      ),
    );
  }
}

class _AnimatedProgressRing extends StatelessWidget {
  const _AnimatedProgressRing({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: percent / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: WorkoutTheme.card.withValues(alpha: 0.7),
                color: WorkoutTheme.primary,
                strokeCap: StrokeCap.round,
              ),
              Text('$percent%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: WorkoutTheme.forest)),
            ],
          ),
        );
      },
    );
  }
}
