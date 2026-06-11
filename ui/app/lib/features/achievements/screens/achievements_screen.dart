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
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  static const _previewUnlockedCount = 2;

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
  int _selectedTabIndex = 0; // 0 for In Progress (Quests), 1 for Unlocked (Badges)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () async {
              await context.push(AppRoutes.shop);
              if (context.mounted) {
                context.read<AchievementsCubit>().load();
              }
            },
            icon: const Icon(Icons.storefront_rounded),
            color: Colors.amber.shade700,
            tooltip: 'SyncCoins Shop',
          ),
        ],
      ),
      body: BlocBuilder<AchievementsCubit, AchievementsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            );
          }

          if (state.status == AchievementsStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off_outlined, size: 56, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text(
                      state.error ?? 'Failed to load achievements.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => context.read<AchievementsCubit>().load(),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final inventory = state.inventory;
          final g = inventory?.gamification;
          final achievements = inventory?.achievements ?? [];
          final inProgress = inventory?.inProgressAchievements ?? [];

          return RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () => context.read<AchievementsCubit>().load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                // ── Gamification stats ─────────────────────────────────────
                if (g != null) _GamificationHeader(g: g),
                const SizedBox(height: 16),

                // ── Log Activity button ────────────────────────────────────
                _LogActivityButton(onLogged: () {
                  context.read<AchievementsCubit>().load();
                }),
                const SizedBox(height: 24),

                // ── Custom Segmented Tab Bar (Capsule Style) ───────────────
                Row(
                  children: [
                    _buildTabButton(
                      index: 0,
                      label: 'Thử thách (${inProgress.length})',
                      isActive: _selectedTabIndex == 0,
                      onTap: () => setState(() => _selectedTabIndex = 0),
                    ),
                    const SizedBox(width: 12),
                    _buildTabButton(
                      index: 1,
                      label: 'Huy chương (${achievements.length})',
                      isActive: _selectedTabIndex == 1,
                      onTap: () => setState(() => _selectedTabIndex = 1),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Tab Contents ───────────────────────────────────────────
                if (_selectedTabIndex == 0) ...[
                  if (inProgress.isEmpty)
                    const _EmptyTabState(
                      message: 'Bạn đã hoàn thành tất cả thử thách hiện tại!',
                      icon: Icons.done_all_rounded,
                    )
                  else
                    ...inProgress.map((p) => _ProgressCard(item: p)),
                ] else ...[
                  if (achievements.isEmpty)
                    _EmptyAchievements()
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: achievements.length,
                      itemBuilder: (context, index) {
                        final item = achievements[index];
                        return _BadgeGridItem(item: item);
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primaryGreen : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.primaryGreen : AppColors.border,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isActive ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Progress Card (Quest list) ────────────────────────────────────────────
  bool _statsPanelOpen = false;

  void _toggleStatsPanel() {
    setState(() => _statsPanelOpen = !_statsPanelOpen);
  }

  void _closeStatsPanel() {
    if (_statsPanelOpen) setState(() => _statsPanelOpen = false);
  }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
  void _showAllUnlocked(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
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
                      '${AchievementDisplayData.unlocked.length} thành tựu',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AchievementsTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 6,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.currentValue} / ${item.requiredValue}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                ),
              ),
              if (item.xpReward > 0)
                Text(
                  '+${item.xpReward} XP',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _colorForCode(String code) {
    if (code.startsWith('STREAK')) return const Color(0xFFE65100);
    if (code.startsWith('PERFECT')) return const Color(0xFF6A1B9A);
    if (code.startsWith('LEVEL')) return const Color(0xFF1565C0);
    return AppColors.primaryGreen;
  }

  static IconData _iconForCode(String code) {
    if (code.startsWith('STREAK')) return Icons.local_fire_department_rounded;
    if (code.startsWith('PERFECT')) return Icons.star_rounded;
    if (code.startsWith('LEVEL')) return Icons.military_tech_rounded;
    return Icons.emoji_events_rounded;
  }
}

// ─── Badge Grid Item ────────────────────────────────────────────────────────

class _BadgeGridItem extends StatelessWidget {
  const _BadgeGridItem({required this.item});

  final AchievementItem item;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  void _showDetailBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final dateLabel = _formatDate(item.unlockedAt);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top handle bar
                Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),

                // Medal Icon Container
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade400, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),

                // Name
                Text(
                  item.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Rewards & Info Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (item.xpReward > 0)
                        _buildStatCol(
                          'XP',
                          '+${item.xpReward} XP',
                          Icons.star_rounded,
                          Colors.purple.shade400,
                        ),
                      if (item.coinReward > 0)
                        _buildStatCol(
                          'SyncCoins',
                          '+${item.coinReward}',
                          Icons.monetization_on_rounded,
                          Colors.amber.shade700,
                        ),
                      if (dateLabel.isNotEmpty)
                        _buildStatCol(
                          'Đạt được ngày',
                          dateLabel,
                          Icons.calendar_today_outlined,
                          AppColors.textMuted,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCol(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailBottomSheet(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular Badge
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber.shade300, Colors.orange.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 8),
          // Badge Name
          Text(
            item.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Activity button ──────────────────────────────────────────────────────

class _LogActivityButton extends StatefulWidget {
  const _LogActivityButton({required this.onLogged});
  final VoidCallback onLogged;

              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: AchievementDisplayData.unlocked
                      .map((item) => UnlockedAchievementCard(achievement: item))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const panelWidth = AchievementsTheme.statsPanelWidth;
    const animDuration = Duration(milliseconds: AchievementsTheme.panelAnimationMs);

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
        );
        widget.onLogged();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _loading ? null : _log,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE65100),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          tooltip: 'Your stats',
        ),
        title: const Text(
          'Achievements',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Gamification header ──────────────────────────────────────────────────────

class _GamificationHeader extends StatelessWidget {
  const _GamificationHeader({required this.g});

  final GamificationSummary g;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen,
            AppColors.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: AchievementsTheme.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.shop),
            icon: const Icon(Icons.storefront_outlined),
            color: AchievementsTheme.textSecondary,
            tooltip: 'SyncCoins Shop',
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Level progress row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.military_tech_rounded, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${g.currentLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
          // ── Main scroll content ───────────────────────────────────────
          BlocBuilder<AchievementsCubit, AchievementsState>(
            builder: (context, state) {
              if (state.isLoading && state.inventory == null) {
                return const Center(
                  child: CircularProgressIndicator(color: AchievementsTheme.progress),
                );
              }

              final previewUnlocked = AchievementDisplayData.unlocked
                  .take(AchievementsScreen._previewUnlockedCount)
                  .toList();

              return RefreshIndicator(
                color: AchievementsTheme.progress,
                onRefresh: () => context.read<AchievementsCubit>().load(),
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const AchievementsSectionHeader(title: 'Đang tiến tới'),
                          ...AchievementDisplayData.inProgress.asMap().entries.map(
                                (e) => InProgressAchievementCard(
                                  achievement: e.value,
                                  gradientIndex: e.key,
                                ),
                              ),
                          const SizedBox(height: 8),
                          AchievementsSectionHeader(
                            title: 'Đã mở khóa',
                            onSeeMore: AchievementDisplayData.unlocked.length >
                                    AchievementsScreen._previewUnlockedCount
                                ? () => _showAllUnlocked(context)
                                : null,
                          ),
                          ...previewUnlocked.map(
                            (item) => UnlockedAchievementCard(achievement: item),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // XP progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (g.currentXp % 1000) / 1000.0,
                        minHeight: 5,
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${g.currentXp % 1000} / 1000 XP để lên cấp',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // ── Dim backdrop when panel open ──────────────────────────────
          AnimatedOpacity(
            opacity: _statsPanelOpen ? 1 : 0,
            duration: animDuration,
            curve: Curves.easeOut,
            child: IgnorePointer(
              ignoring: !_statsPanelOpen,
              child: GestureDetector(
                onTap: _closeStatsPanel,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats grid
          Row(
            children: [
              _StatBox(label: 'XP', value: '${g.currentXp}', emoji: '⭐'),
              _StatBox(label: 'Streak', value: '${g.currentStreak}d', emoji: '🔥'),
              _StatBox(label: 'Coins', value: '${g.syncCoins.toInt()}', emoji: '💰'),
              _StatBox(label: 'Points', value: '${g.achievementPoints}', emoji: '🎯'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.emoji});

  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyAchievements extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 36, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có huy chương nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy tiếp tục tập luyện và hoàn thành thử thách để mở khóa huy chương đầu tiên!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.message, required this.icon});
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.primaryGreen),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
        ],
            ),
          ),

          // ── Slide-in stats panel ──────────────────────────────────────
          AnimatedPositioned(
            duration: animDuration,
            curve: Curves.easeOutCubic,
            left: _statsPanelOpen ? 0 : -panelWidth,
            top: 0,
            bottom: 0,
            width: panelWidth,
            child: AchievementsStatsPanel(onClose: _closeStatsPanel),
          ),
        ],
      ),
      ),
    );
  }
}
