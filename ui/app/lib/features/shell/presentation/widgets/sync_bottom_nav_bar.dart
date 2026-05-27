import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

class SyncBottomNavBar extends StatelessWidget {
  const SyncBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCenterActionTap,
    required this.onAgentTap,
  });

  /// 0 = Home, 1 = Profile, 2 = Support, 3 = Settings
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCenterActionTap;
  final VoidCallback onAgentTap;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: 96 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 72 + bottomPadding,
              padding: EdgeInsets.only(bottom: bottomPadding, left: 8, right: 8),
              decoration: const BoxDecoration(
                color: SyncColors.surface,
                border: Border(
                  top: BorderSide(color: Color(0xFF1E2A36)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavIcon(
                    icon: Icons.home_rounded,
                    selected: currentIndex == 0,
                    onTap: () => onTabSelected(0),
                  ),
                  _NavIcon(
                    icon: Icons.person_outline_rounded,
                    selected: currentIndex == 1,
                    onTap: () => onTabSelected(1),
                  ),
                  const SizedBox(width: 56),
                  _NavIcon(
                    icon: Icons.support_agent_rounded,
                    selected: currentIndex == 2,
                    onTap: () => onTabSelected(2),
                  ),
                  _NavIcon(
                    icon: Icons.settings_outlined,
                    selected: currentIndex == 3,
                    onTap: () => onTabSelected(3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 36 + bottomPadding,
            child: _CenterFab(onTap: onCenterActionTap),
          ),
          Positioned(
            right: 28,
            bottom: 44 + bottomPadding,
            child: _AgentFab(onTap: onAgentTap),
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (selected) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: SyncColors.cyan,
            boxShadow: SyncColors.cyanGlow(blur: 16),
          ),
          child: Icon(icon, color: const Color(0xFF041014), size: 26),
        ),
      );
    }

    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: SyncColors.iconMuted, size: 28),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: SyncColors.cyanGlow(blur: 28, spread: 2),
      ),
      child: Material(
        color: SyncColors.cyan,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.add, color: Color(0xFF041014), size: 36),
          ),
        ),
      ),
    );
  }
}

class _AgentFab extends StatelessWidget {
  const _AgentFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SyncColors.surfaceElevated,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: SyncColors.cyan.withValues(alpha: 0.35)),
          ),
          child: const Icon(
            Icons.smart_toy_outlined,
            color: SyncColors.cyan,
            size: 26,
          ),
        ),
      ),
    );
  }
}
