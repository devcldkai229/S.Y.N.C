import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';

class AiRoadmapBandChip extends StatelessWidget {
  const AiRoadmapBandChip({
    super.key,
    required this.label,
    required this.data,
  });

  final String label;
  final BandChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: data.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: data.accent.withValues(alpha: 0.85))),
          const SizedBox(height: 4),
          Text(data.label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: data.accent)),
        ],
      ),
    );
  }
}
