import 'package:flutter/material.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';

class FoodRow extends StatelessWidget {
  const FoodRow({
    super.key,
    required this.name,
    required this.subtitle,
    this.onTap,
    this.onAdd,
    this.onDelete,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final VoidCallback? onDelete;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: NutritionTheme.textMuted)),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (onAdd != null)
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: NutritionTheme.primary),
              ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.close, size: 20, color: NutritionTheme.textMuted),
              ),
          ],
        ),
      ),
    );
  }
}
