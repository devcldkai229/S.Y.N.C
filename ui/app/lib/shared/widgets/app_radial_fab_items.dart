import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/shared/widgets/draggable_radial_fab.dart';

/// Shared radial FAB menu items used on the main shell and overlay feature screens.
abstract final class AppRadialFabItems {
  static List<RadialFabMenuItem> build(BuildContext context) {
    return [
      RadialFabMenuItem(
        icon: Icons.emoji_events_rounded,
        label: 'Achievements',
        onTap: () => context.go(AppRoutes.achievements),
      ),
      RadialFabMenuItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Subscription',
        onTap: () => context.go(AppRoutes.subscription),
      ),
      RadialFabMenuItem(
        icon: Icons.flag_rounded,
        label: 'Challenges',
        onTap: () => context.go(AppRoutes.challengesMap),
      ),
      RadialFabMenuItem(
        icon: Icons.eco_rounded,
        label: 'Nutrition',
        onTap: () => context.go(AppRoutes.nutritionDiary),
      ),
      RadialFabMenuItem(
        icon: Icons.storefront_rounded,
        label: 'Sync Foods',
        onTap: () => context.go(AppRoutes.marketplaceHome),
      ),
      RadialFabMenuItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Đơn hàng',
        onTap: () => context.go(AppRoutes.orderList),
      ),
    ];
  }
}
