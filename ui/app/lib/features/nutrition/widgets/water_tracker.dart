import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';

class WaterTracker extends StatelessWidget {
  const WaterTracker({
    super.key,
    required this.intakeMl,
    required this.targetMl,
    required this.onAdd,
  });

  final int intakeMl;
  final int targetMl;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final liters = intakeMl / 1000;
    final targetLiters = targetMl / 1000;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: NutritionTheme.cardDecoration(),
      child: Row(
        children: [
          const Icon(Icons.water_drop_outlined, color: NutritionTheme.water),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nước uống', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${liters.toStringAsFixed(1)} / ${targetLiters.toStringAsFixed(1)} L',
                  style: const TextStyle(color: NutritionTheme.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: () {
              HapticFeedback.lightImpact();
              onAdd();
            },
            style: IconButton.styleFrom(backgroundColor: NutritionTheme.water),
            icon: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
