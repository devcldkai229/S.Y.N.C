import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/shared/widgets/draggable_radial_fab.dart';

/// Shared radial FAB menu items used on the main shell and overlay feature screens.
abstract final class AppRadialFabItems {
  static List<RadialFabMenuItem> build(BuildContext context) {
    final activeCount = getIt<ActiveOrderCountNotifier>().count;

    return [
      RadialFabMenuItem(
        icon: Icons.emoji_events_rounded,
        label: 'Achievements',
        onTap: () => context.push(AppRoutes.achievements),
      ),
      RadialFabMenuItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Subscription',
        onTap: () => context.push(AppRoutes.subscription),
      ),
      RadialFabMenuItem(
        icon: Icons.flag_rounded,
        label: 'Challenges',
        onTap: () => context.push(AppRoutes.challengesMap),
      ),
      RadialFabMenuItem(
        icon: Icons.eco_rounded,
        label: 'Nutrition',
        onTap: () => context.push(AppRoutes.nutritionDiary),
      ),
      RadialFabMenuItem(
        icon: Icons.storefront_rounded,
        label: 'Sync Foods',
        onTap: () => context.push(AppRoutes.marketplaceHome),
      ),
      RadialFabMenuItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Đơn hàng',
        badgeCount: activeCount > 0 ? activeCount : null,
        onTap: () => context.push(AppRoutes.orderList),
      ),
    ];
  }
}
