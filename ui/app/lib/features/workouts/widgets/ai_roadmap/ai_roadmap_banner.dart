import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class AiRoadmapBanner extends StatelessWidget {
  const AiRoadmapBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            WorkoutTheme.primary.withValues(alpha: 0.12),
            WorkoutTheme.lime.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WorkoutTheme.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Text('✨', style: TextStyle(fontSize: 18)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Lộ trình do SYNC AI tạo & tự điều chỉnh',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WorkoutTheme.textPrimary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
