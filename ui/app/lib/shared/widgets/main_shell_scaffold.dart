import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/shared/widgets/app_bottom_nav_bar.dart';

/// Bottom navigation shell — dùng với [StatefulShellRoute].
class MainShellScaffold extends StatelessWidget {
  const MainShellScaffold({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  AppNavTab get _currentTab {
    switch (navigationShell.currentIndex) {
      case 0:
        return AppNavTab.home;
      case 1:
        return AppNavTab.workouts;
      case 2:
        return AppNavTab.social;
      case 3:
        return AppNavTab.profile;
      default:
        return AppNavTab.home;
    }
  }

  void _onTabSelected(AppNavTab tab) {
    final index = switch (tab) {
      AppNavTab.home => 0,
      AppNavTab.workouts => 1,
      AppNavTab.social => 2,
      AppNavTab.profile => 3,
    };
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavBar(
        currentTab: _currentTab,
        onTabSelected: _onTabSelected,
        onCenterTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.quickActionsComingSoon)),
          );
        },
      ),
    );
  }
}
