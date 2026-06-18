import 'package:flutter/material.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';

enum AppNavTab { home, workouts, social, profile }

/// Visible nav row height (excludes device safe-area inset).
const double kAppBottomNavBarHeight = 72;

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    this.currentTab,
    required this.onTabSelected,
    this.showProfileBadge = false,
  });

  /// When null, no tab is highlighted (overlay screens outside the shell).
  final AppNavTab? currentTab;
  final ValueChanged<AppNavTab> onTabSelected;
  final bool showProfileBadge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: kAppBottomNavBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: l10n.navHome,
                selected: currentTab == AppNavTab.home,
                onTap: () => onTabSelected(AppNavTab.home),
              ),
              _NavItem(
                icon: Icons.fitness_center_outlined,
                label: l10n.navWorkouts,
                selected: currentTab == AppNavTab.workouts,
                onTap: () => onTabSelected(AppNavTab.workouts),
              ),
              const _CenterFabPlaceholder(),
              _NavItem(
                icon: Icons.groups_outlined,
                label: l10n.navSocial,
                selected: currentTab == AppNavTab.social,
                onTap: () => onTabSelected(AppNavTab.social),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: l10n.navProfile,
                selected: currentTab == AppNavTab.profile,
                showBadge: showProfileBadge,
                onTap: () => onTabSelected(AppNavTab.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryGreen : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 26),
                if (showBadge)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brightGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reserves horizontal space for the docked center FAB in [DraggableRadialFab].
class _CenterFabPlaceholder extends StatelessWidget {
  const _CenterFabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 72);
  }
}
