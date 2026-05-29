import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/shared/widgets/app_bottom_nav_bar.dart';

/// Bottom navigation shell — used with [StatefulShellRoute].
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
        onCenterTap: () => _showQuickActions(context),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _QuickActionsSheet(
        onAchievementsTap: () {
          Navigator.pop(context);
          context.push(AppRoutes.achievements);
        },
        onSubscriptionTap: () {
          Navigator.pop(context);
          context.push(AppRoutes.subscription);
        },
      ),
    );
  }
}

// ─── Quick Actions Sheet ──────────────────────────────────────────────────────

class _QuickActionsSheet extends StatelessWidget {
  const _QuickActionsSheet({
    required this.onAchievementsTap,
    required this.onSubscriptionTap,
  });

  final VoidCallback onAchievementsTap;
  final VoidCallback onSubscriptionTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Actions grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
              children: [
                _ActionTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  color: Colors.amber.shade700,
                  onTap: onAchievementsTap,
                ),
                _ActionTile(
                  icon: Icons.workspace_premium_rounded,
                  label: 'Subscription',
                  color: AppColors.primaryGreen,
                  onTap: onSubscriptionTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
