import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';

class SessionProgressBar extends StatelessWidget {
  const SessionProgressBar({
    super.key,
    this.sessionTitle,
    required this.exerciseIndex,
    required this.exerciseTotal,
    required this.setIndex,
    required this.setTotal,
    required this.overallProgress,
  });

  final String? sessionTitle;
  final int exerciseIndex;
  final int exerciseTotal;
  final int setIndex;
  final int setTotal;
  final double overallProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      color: ExecutionTheme.offWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Exercise $exerciseIndex of $exerciseTotal · Set $setIndex of $setTotal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ExecutionTheme.slateDark),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overallProgress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: ExecutionTheme.border,
              color: ExecutionTheme.syncLime,
            ),
          ),
        ],
      ),
    );
  }
}
