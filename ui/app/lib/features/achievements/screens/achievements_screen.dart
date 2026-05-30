import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/achievements/cubit/achievements_cubit.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

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

class _AchievementsView extends StatelessWidget {
  const _AchievementsView();

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
            onPressed: () => context.push(AppRoutes.shop),
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
          final total = inventory?.totalAchievementsUnlocked ?? 0;

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
                _LogActivityButton(),
                const SizedBox(height: 20),

                // ── In Progress ────────────────────────────────────────────
                if (inProgress.isNotEmpty) ...[
                  _SectionHeader(
                    icon: Icons.trending_up_rounded,
                    iconColor: Colors.orange.shade600,
                    title: 'Đang tiến tới',
                  ),
                  const SizedBox(height: 12),
                  ...inProgress.map((p) => _ProgressCard(item: p)),
                  const SizedBox(height: 20),
                ],

                // ── Achievements header ─────────────────────────────────────
                _SectionHeader(
                  icon: Icons.emoji_events_rounded,
                  iconColor: AppColors.primaryGreen,
                  title: 'Đã mở khóa',
                  badge: '$total unlocked',
                ),
                const SizedBox(height: 12),

                // ── Achievement list ────────────────────────────────────────
                if (achievements.isEmpty)
                  _EmptyAchievements()
                else
                  ...achievements.map((a) => _AchievementCard(item: a)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badge,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (badge != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Progress Card ────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.item});

  final AchievementProgressItem item;

  @override
  Widget build(BuildContext context) {
    final pct = (item.progress * 100).round();
    final color = _colorForCode(item.code);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForCode(item.code), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 15,
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
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.currentValue} / ${item.requiredValue}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              if (item.xpReward > 0)
                Text(
                  '+${item.xpReward} XP khi hoàn thành',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.8),
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

// ─── Log Activity button ──────────────────────────────────────────────────────

class _LogActivityButton extends StatefulWidget {
  @override
  State<_LogActivityButton> createState() => _LogActivityButtonState();
}

class _LogActivityButtonState extends State<_LogActivityButton> {
  bool _loading = false;

  Future<void> _log() async {
    setState(() => _loading = true);
    try {
      final result = await getIt<ProfileApiService>().logActivity();
      if (!mounted) return;
      if (result.alreadyLoggedToday) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hôm nay bạn đã ghi nhận rồi! Streak: ${result.currentStreak} ngày 🔥'),
            backgroundColor: Colors.orange.shade700,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.newlyUnlockedAchievements.isEmpty
                  ? 'Đã ghi nhận! Streak: ${result.currentStreak} ngày 🔥'
                  : 'Streak: ${result.currentStreak} ngày 🔥  Mở khóa: ${result.newlyUnlockedAchievements.join(', ')}',
            ),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        if (mounted) context.read<AchievementsCubit>().load();
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
        ),
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.local_fire_department_rounded, color: Colors.white),
        label: Text(
          _loading ? 'Đang ghi nhận...' : 'Ghi nhận hoạt động hôm nay',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 15,
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
            AppColors.primaryGreen.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Level badge row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.military_tech_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Level ${g.currentLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
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
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.item});

  final AchievementItem item;

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(item.unlockedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trophy icon badge
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.description.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
                const SizedBox(height: 8),
                // Reward chips row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.xpReward > 0)
                      _RewardChip(
                        label: '+${item.xpReward} XP',
                        color: Colors.purple.shade400,
                        icon: Icons.star_rounded,
                      ),
                    if (item.coinReward > 0)
                      _RewardChip(
                        label: '+${item.coinReward} coins',
                        color: Colors.amber.shade700,
                        icon: Icons.monetization_on_rounded,
                      ),
                    if (dateLabel.isNotEmpty)
                      _RewardChip(
                        label: dateLabel,
                        color: AppColors.textMuted,
                        icon: Icons.calendar_today_outlined,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 40, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'No achievements yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep working out, logging meals, and engaging with the community to unlock your first achievement!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
