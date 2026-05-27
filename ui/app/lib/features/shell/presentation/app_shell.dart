import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/sync_colors.dart';
import 'package:sync_app/features/shell/presentation/widgets/app_header.dart';
import 'package:sync_app/features/shell/presentation/widgets/sync_bottom_nav_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.navigationShell,
    this.displayName = 'Khai',
    this.avatarUrl,
  });

  final StatefulNavigationShell navigationShell;
  final String displayName;
  final String? avatarUrl;

  int get _currentTabIndex {
    final index = navigationShell.currentIndex;
    return index > 3 ? 0 : index;
  }

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  void _onCenterActionTap(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: SyncColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hành động nhanh',
              style: TextStyle(
                color: SyncColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Bắt đầu buổi tập, ghi nhận bữa ăn, hoặc hỏi AI coach.',
              style: TextStyle(color: SyncColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _onAgentTap(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI Agent — sắp có')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SyncColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(
              displayName: displayName,
              avatarUrl: avatarUrl,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: SyncBottomNavBar(
        currentIndex: _currentTabIndex,
        onTabSelected: _onTabSelected,
        onCenterActionTap: () => _onCenterActionTap(context),
        onAgentTap: () => _onAgentTap(context),
      ),
    );
  }
}
