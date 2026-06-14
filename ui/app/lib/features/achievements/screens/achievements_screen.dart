import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/achievements/cubit/achievements_cubit.dart';
import 'package:sync_app/features/achievements/models/achievement_display_data.dart';
import 'package:sync_app/features/achievements/widgets/achievements_stats_panel.dart';
import 'package:sync_app/features/achievements/widgets/achievements_theme.dart';
import 'package:sync_app/features/achievements/widgets/in_progress_achievement_card.dart';
import 'package:sync_app/features/achievements/widgets/section_header.dart';
import 'package:sync_app/features/achievements/widgets/unlocked_achievement_card.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AchievementsCubit(getIt())..load(),
      child: const _AchievementsView(),
    );
  }
}

class _AchievementsView extends StatefulWidget {
  const _AchievementsView();

  @override
  State<_AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<_AchievementsView> {
  bool _statsPanelOpen = false;
  int _tabIndex = 0;

  static const _panelWidth = AchievementsTheme.statsPanelWidth;
  static const _animDuration = Duration(milliseconds: AchievementsTheme.panelAnimationMs);

  void _toggleStatsPanel() => setState(() => _statsPanelOpen = !_statsPanelOpen);

  void _closeStatsPanel() {
    if (_statsPanelOpen) setState(() => _statsPanelOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppShellOverlayScaffold(
      child: Scaffold(
        backgroundColor: AchievementsTheme.background,
        appBar: AppBar(
          backgroundColor: AchievementsTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _toggleStatsPanel,
            icon: Icon(
              _statsPanelOpen ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: AchievementsTheme.textPrimary,
            ),
            tooltip: 'Thống kê',
          ),
          title: const Text(
            'Achievements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AchievementsTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await context.push(AppRoutes.shop);
                if (context.mounted) context.read<AchievementsCubit>().load();
              },
              icon: const Icon(Icons.storefront_outlined),
              color: AchievementsTheme.textSecondary,
              tooltip: 'SyncCoins Shop',
            ),
          ],
        ),
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            BlocBuilder<AchievementsCubit, AchievementsState>(
              builder: (context, state) {
                if (state.isLoading && state.inventory == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: AchievementsTheme.progress),
                  );
                }

                if (state.status == AchievementsStatus.failure && state.inventory == null) {
                  return _ErrorState(
                    message: state.error ?? 'Không tải được achievements.',
                    onRetry: () => context.read<AchievementsCubit>().load(),
                  );
                }

                final inventory = state.inventory;
                final inProgress = _mapInProgress(inventory);
                final unlocked = _mapUnlocked(inventory);
                return RefreshIndicator(
                  color: AchievementsTheme.progress,
                  onRefresh: () => context.read<AchievementsCubit>().load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            _TabSwitcher(
                              tabIndex: _tabIndex,
                              inProgressCount: inProgress.length,
                              unlockedCount: unlocked.length,
                              onChanged: (i) => setState(() => _tabIndex = i),
                            ),
                            const SizedBox(height: 20),
                            if (_tabIndex == 0)
                              _InProgressSection(items: inProgress)
                            else
                              _UnlockedSection(
                                items: unlocked,
                                onSeeAll: () => _showAllUnlocked(context, unlocked),
                              ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            AnimatedOpacity(
              opacity: _statsPanelOpen ? 1 : 0,
              duration: _animDuration,
              curve: Curves.easeOut,
              child: IgnorePointer(
                ignoring: !_statsPanelOpen,
                child: GestureDetector(
                  onTap: _closeStatsPanel,
                  child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _animDuration,
              curve: Curves.easeOutCubic,
              left: _statsPanelOpen ? 0 : -_panelWidth,
              top: 0,
              bottom: 0,
              width: _panelWidth,
              child: BlocBuilder<AchievementsCubit, AchievementsState>(
                builder: (context, state) {
                  final stats = _mapStats(state.inventory?.gamification);
                  return AchievementsStatsPanel(stats: stats, onClose: _closeStatsPanel);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllUnlocked(BuildContext context, List<UnlockedAchievement> items) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AchievementsTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    const Text(
                      'Đã mở khóa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AchievementsTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} thành tựu',
                      style: const TextStyle(fontSize: 13, color: AchievementsTheme.textMuted),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: items.map((a) => UnlockedAchievementCard(achievement: a)).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data mapping ─────────────────────────────────────────────────────────────

List<InProgressAchievement> _mapInProgress(UserInventory? inventory) {
  final api = inventory?.inProgressAchievements ?? [];
  if (api.isNotEmpty) {
    return api
        .map(
          (p) => InProgressAchievement(
            title: p.name,
            description: p.description,
            current: p.currentValue,
            required: p.requiredValue,
            percent: (p.progress * 100).round(),
            icon: _iconForCode(p.code),
          ),
        )
        .toList();
  }
  return AchievementDisplayData.inProgress;
}

List<UnlockedAchievement> _mapUnlocked(UserInventory? inventory) {
  final api = inventory?.achievements ?? [];
  if (api.isNotEmpty) {
    return api
        .map(
          (a) => UnlockedAchievement(
            title: a.name,
            description: a.description,
            xpReward: a.xpReward,
            coinReward: a.coinReward,
          ),
        )
        .toList();
  }
  return AchievementDisplayData.unlocked;
}

UserStatsDisplay _mapStats(GamificationSummary? g) {
  if (g == null) return UserStatsDisplay.demo;
  return UserStatsDisplay(
    level: g.currentLevel,
    xp: g.currentXp,
    streakDays: g.currentStreak,
    coins: g.syncCoins.round(),
    points: g.achievementPoints,
  );
}

IconData _iconForCode(String code) {
  final upper = code.toUpperCase();
  if (upper.startsWith('STREAK')) return Icons.local_fire_department_outlined;
  if (upper.startsWith('PERFECT')) return Icons.star_outline_rounded;
  if (upper.startsWith('LEVEL')) return Icons.military_tech_outlined;
  if (upper.contains('WORKOUT')) return Icons.fitness_center_outlined;
  return Icons.emoji_events_outlined;
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.tabIndex,
    required this.inProgressCount,
    required this.unlockedCount,
    required this.onChanged,
  });

  final int tabIndex;
  final int inProgressCount;
  final int unlockedCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TabPill(
            label: 'Thử thách ($inProgressCount)',
            active: tabIndex == 0,
            onTap: () => onChanged(0),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TabPill(
            label: 'Huy chương ($unlockedCount)',
            active: tabIndex == 1,
            onTap: () => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(colors: [AchievementsTheme.progress, AchievementsTheme.progressEnd])
              : null,
          color: active ? null : AchievementsTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: active ? AchievementsTheme.cardShadow() : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : AchievementsTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Sections ─────────────────────────────────────────────────────────────────

class _InProgressSection extends StatelessWidget {
  const _InProgressSection({required this.items});

  final List<InProgressAchievement> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.done_all_rounded,
        message: 'Bạn đã hoàn thành tất cả thử thách hiện tại!',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AchievementsSectionHeader(title: 'Đang tiến tới'),
        ...items.asMap().entries.map(
              (e) => InProgressAchievementCard(
                achievement: e.value,
                gradientIndex: e.key,
              ),
            ),
      ],
    );
  }
}

class _UnlockedSection extends StatelessWidget {
  const _UnlockedSection({required this.items, required this.onSeeAll});

  final List<UnlockedAchievement> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState(
        icon: Icons.emoji_events_outlined,
        message: 'Chưa có huy chương nào — hãy hoàn thành thử thách để mở khóa!',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AchievementsSectionHeader(
          title: 'Đã mở khóa',
          trailing: '${items.length} huy chương',
          onSeeMore: items.length > 6 ? onSeeAll : null,
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length > 6 ? 6 : items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _BadgeTile(
              title: item.title,
              onTap: () => _showBadgeDetail(context, item),
            );
          },
        ),
      ],
    );
  }

  void _showBadgeDetail(BuildContext context, UnlockedAchievement item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AchievementsTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AchievementsTheme.goldGradientStart, AchievementsTheme.goldGradientEnd],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: AchievementsTheme.goldCardShadow,
                ),
                child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AchievementsTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AchievementsTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              if (item.xpReward > 0 || item.coinReward > 0) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (item.xpReward > 0)
                      _RewardPill(label: '+${item.xpReward} XP', color: AchievementsTheme.chipXpText),
                    if (item.xpReward > 0 && item.coinReward > 0) const SizedBox(width: 10),
                    if (item.coinReward > 0)
                      _RewardPill(label: '+${item.coinReward} coins', color: AchievementsTheme.chipCoinText),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AchievementsTheme.goldGradientStart, AchievementsTheme.goldGradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: AchievementsTheme.goldCardShadow,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AchievementsTheme.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardPill extends StatelessWidget {
  const _RewardPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AchievementsTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AchievementsTheme.progress),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AchievementsTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 56, color: AchievementsTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AchievementsTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AchievementsTheme.progress),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
