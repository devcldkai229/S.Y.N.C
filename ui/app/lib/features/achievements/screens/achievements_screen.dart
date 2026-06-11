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
  bool _statsPanelOpen = false;

  void _toggleStatsPanel() {
    setState(() => _statsPanelOpen = !_statsPanelOpen);
  }

  void _closeStatsPanel() {
    if (_statsPanelOpen) setState(() => _statsPanelOpen = false);
  }

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
          tooltip: 'Your stats',
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
