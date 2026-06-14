import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:sync_app/shared/widgets/app_radial_fab_items.dart';
import 'package:sync_app/shared/widgets/draggable_radial_fab.dart';

/// Wraps full-screen feature routes (Achievements, Subscription, …) with the
/// same bottom nav + radial FAB as [MainShellScaffold].
class AppShellOverlayScaffold extends StatelessWidget {
  const AppShellOverlayScaffold({
    super.key,
    required this.child,
  });

  final Widget child;

  void _onTabSelected(BuildContext context, AppNavTab tab) {
    final route = switch (tab) {
      AppNavTab.home => AppRoutes.home,
      AppNavTab.workouts => AppRoutes.workouts,
      AppNavTab.social => AppRoutes.social,
      AppNavTab.profile => AppRoutes.profile,
    };
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: child,
          bottomNavigationBar: AppBottomNavBar(
            onTabSelected: (tab) => _onTabSelected(context, tab),
          ),
        ),
        ListenableBuilder(
          listenable: getIt<ActiveOrderCountNotifier>(),
          builder: (context, _) => DraggableRadialFab(items: AppRadialFabItems.build(context)),
        ),
      ],
    );
  }
}
