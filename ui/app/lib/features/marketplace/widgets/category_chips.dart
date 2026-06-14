import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

class CategoryChips extends StatelessWidget {
  const CategoryChips({super.key, required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  static const _categories = ['All', 'Healthy', 'Cơm', 'Salad', 'Combo', 'Đồ uống'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = _categories[i];
          final active = c == selected;
          return FilterChip(
            label: Text(c),
            selected: active,
            onSelected: (_) => onSelected(c),
            selectedColor: MarketplaceTheme.primary.withValues(alpha: 0.15),
            checkmarkColor: MarketplaceTheme.primary,
          );
        },
      ),
    );
  }
}
