import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

enum AppNavTab { home, workouts, social, profile }

class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
    this.onCenterTap,
    this.showProfileBadge = false,
  });

  final AppNavTab currentTab;
  final ValueChanged<AppNavTab> onTabSelected;
  final VoidCallback? onCenterTap;
  final bool showProfileBadge;

  @override
  Widget build(BuildContext context) {
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
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                selected: currentTab == AppNavTab.home,
                onTap: () => onTabSelected(AppNavTab.home),
              ),
              _NavItem(
                icon: Icons.fitness_center_outlined,
                label: 'Workouts',
                selected: currentTab == AppNavTab.workouts,
                onTap: () => onTabSelected(AppNavTab.workouts),
              ),
              _CenterFab(onTap: onCenterTap),
              _NavItem(
                icon: Icons.groups_outlined,
                label: 'Social',
                selected: currentTab == AppNavTab.social,
                onTap: () => onTabSelected(AppNavTab.social),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
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

class _CenterFab extends StatelessWidget {
  const _CenterFab({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -18),
      child: Material(
        elevation: 6,
        shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        color: AppColors.primaryGreen,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.add, color: Colors.white, size: 30),
          ),
        ),
      ),
    );
  }
}
