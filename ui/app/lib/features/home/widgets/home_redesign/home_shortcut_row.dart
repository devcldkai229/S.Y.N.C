import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeShortcutRow extends StatelessWidget {
  const HomeShortcutRow({super.key});

  static const _items = [
    _ShortcutItem(
      label: 'Tập luyện',
      icon: Icons.fitness_center_rounded,
      route: AppRoutes.workouts,
    ),
    _ShortcutItem(
      label: 'Sync Foods',
      icon: Icons.restaurant_rounded,
      route: AppRoutes.marketplaceHome,
    ),
    _ShortcutItem(
      label: 'Dinh dưỡng',
      icon: Icons.eco_rounded,
      route: AppRoutes.nutritionDiary,
    ),
    _ShortcutItem(
      label: 'Cộng đồng',
      icon: Icons.people_rounded,
      route: AppRoutes.social,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ShortcutTile(
                  label: item.label,
                  icon: item.icon,
                  onTap: () => context.go(item.route),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ShortcutItem {
  const _ShortcutItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class ShortcutTile extends StatelessWidget {
  const ShortcutTile({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeBentoColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeBentoColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: HomeBentoColors.primaryGreen, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: HomeBentoColors.textPrimary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
