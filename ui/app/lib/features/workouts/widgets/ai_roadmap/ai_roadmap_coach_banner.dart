import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class AiRoadmapCoachBanner extends StatelessWidget {
  const AiRoadmapCoachBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WorkoutTheme.lime.withValues(alpha: 0.35),
        borderRadius: WorkoutTheme.radiusMd,
        border: Border.all(color: WorkoutTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.wb_sunny_outlined, size: 20, color: WorkoutTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: WorkoutTheme.textPrimary, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
