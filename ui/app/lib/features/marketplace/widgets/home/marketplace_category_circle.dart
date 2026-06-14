import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

class MarketplaceCategoryRow extends StatelessWidget {
  const MarketplaceCategoryRow({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  final List<CategoryItem> categories;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          if (i == 0) {
            return MarketplaceCategoryCircle(
              label: 'Tất cả',
              icon: MarketplaceCatalog.allCategoryIcon,
              selected: selectedId == null,
              onTap: () {
                HapticFeedback.lightImpact();
                onSelected(null);
              },
            );
          }
          final cat = categories[i - 1];
          return MarketplaceCategoryCircle(
            label: cat.label,
            icon: MarketplaceCatalog.iconForCategoryId(cat.id),
            selected: selectedId == cat.id,
            onTap: () {
              HapticFeedback.lightImpact();
              onSelected(cat.id);
            },
          );
        },
      ),
    );
  }
}

class MarketplaceCategoryCircle extends StatelessWidget {
  const MarketplaceCategoryCircle({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? MarketplaceTheme.primary : MarketplaceTheme.sage;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? MarketplaceTheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: selected
                    ? MarketplaceTheme.lightGreen
                    : MarketplaceTheme.lightGreen.withValues(alpha: 0.65),
                child: Icon(icon, size: 28, color: iconColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? MarketplaceTheme.heading : MarketplaceTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
