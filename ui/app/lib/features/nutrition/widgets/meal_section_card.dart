import 'package:flutter/material.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';
import 'package:sync_app/features/nutrition/widgets/food_row.dart';

class MealSectionCard extends StatelessWidget {
  const MealSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.logs,
    required this.onAdd,
    required this.onDeleteLog,
  });

  final String title;
  final IconData icon;
  final List<MealLog> logs;
  final VoidCallback onAdd;
  final void Function(MealLog log) onDeleteLog;

  int get totalKcal => logs.fold(0, (sum, l) => sum + l.totalCalories);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: NutritionTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: NutritionTheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Text('$totalKcal kcal', style: const TextStyle(color: NutritionTheme.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Chưa có món nào — thêm $title nhé 💪',
                style: const TextStyle(color: NutritionTheme.textMuted, fontSize: 13),
              ),
            )
          else
            ...logs.expand((log) => log.items.map((item) => FoodRow(
                  name: item.foodNameSnapshot,
                  subtitle: '${item.calories} kcal · ${item.quantityGram.toStringAsFixed(0)}g',
                  onDelete: () => onDeleteLog(log),
                ))),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle_outline, color: NutritionTheme.primary),
            label: const Text('Thêm món', style: TextStyle(color: NutritionTheme.primary)),
          ),
        ],
      ),
    );
  }
}
