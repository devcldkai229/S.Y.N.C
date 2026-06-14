import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';

class WorkoutTipsExpansion extends StatelessWidget {
  const WorkoutTipsExpansion({super.key, required this.detail});

  final ExerciseCatalogDetail? detail;

  @override
  Widget build(BuildContext context) {
    if (detail == null) return const SizedBox.shrink();

    final cues = detail!.aiCoachingCues;
    final mistakes = detail!.commonMistakes;
    if (cues.isEmpty && mistakes.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: ExecutionTheme.cardWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ExecutionTheme.border),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          iconColor: ExecutionTheme.slateDark,
          collapsedIconColor: ExecutionTheme.slateMuted,
          title: const Text(
            'Xem mẹo & hướng dẫn',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: ExecutionTheme.slateDark),
          ),
          subtitle: const Text('Hướng dẫn · Lỗi thường gặp', style: TextStyle(fontSize: 12)),
          children: [
            if (cues.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hướng dẫn',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ...cues.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: ExecutionTheme.syncLime),
                      const SizedBox(width: 8),
                      Expanded(child: Text(c, style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
              ),
            ],
            if (mistakes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lỗi thường gặp',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
              ),
              const SizedBox(height: 8),
              ...mistakes.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(child: Text(m, style: const TextStyle(fontSize: 13, height: 1.4))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
