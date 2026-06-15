import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

enum ChallengeRewardsLayout { full, compact, inline }

class _GiftTheme {
  const _GiftTheme({
    required this.icon,
    required this.emoji,
    required this.background,
    required this.accent,
    required this.category,
  });

  final IconData icon;
  final String emoji;
  final Color background;
  final Color accent;
  final String category;
}

_GiftTheme _themeForGift(String name) {
  final lower = name.toLowerCase();

  if (lower.contains('badge') || lower.contains('huy hiệu')) {
    return const _GiftTheme(
      icon: Icons.military_tech_rounded,
      emoji: '🏅',
      background: Color(0xFFFFF7E6),
      accent: Color(0xFFD97706),
      category: 'Huy hiệu',
    );
  }
  if (lower.contains('áo') || lower.contains('shirt') || lower.contains('tee')) {
    return const _GiftTheme(
      icon: Icons.checkroom_rounded,
      emoji: '👕',
      background: Color(0xFFEFF6FF),
      accent: Color(0xFF2563EB),
      category: 'Merch',
    );
  }
  if (lower.contains('voucher') || lower.contains('phiếu')) {
    return const _GiftTheme(
      icon: Icons.confirmation_number_rounded,
      emoji: '🎟️',
      background: Color(0xFFFFF1F2),
      accent: Color(0xFFE11D48),
      category: 'Voucher',
    );
  }
  if (lower.contains('shaker') || lower.contains('bình')) {
    return const _GiftTheme(
      icon: Icons.sports_gymnastics_rounded,
      emoji: '🥤',
      background: Color(0xFFECFEFF),
      accent: Color(0xFF0891B2),
      category: 'Phụ kiện',
    );
  }
  return const _GiftTheme(
    icon: Icons.card_giftcard_rounded,
    emoji: '🎁',
    background: Color(0xFFF3E8FF),
    accent: Color(0xFF7C3AED),
    category: 'Quà tặng',
  );
}

class ChallengeRewardsSection extends StatelessWidget {
  const ChallengeRewardsSection({
    super.key,
    required this.pointRewards,
    required this.gifts,
    this.layout = ChallengeRewardsLayout.full,
    this.showHeader = true,
  });

  final int pointRewards;
  final List<String> gifts;
  final ChallengeRewardsLayout layout;
  final bool showHeader;

  bool get _hasRewards => pointRewards > 0 || gifts.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!_hasRewards) return const SizedBox.shrink();

    return switch (layout) {
      ChallengeRewardsLayout.full => _FullRewards(
          pointRewards: pointRewards,
          gifts: gifts,
          showHeader: showHeader,
        ),
      ChallengeRewardsLayout.compact => _CompactRewards(
          pointRewards: pointRewards,
          gifts: gifts,
        ),
      ChallengeRewardsLayout.inline => _InlineRewards(
          pointRewards: pointRewards,
          gifts: gifts,
        ),
    };
  }
}

class _FullRewards extends StatelessWidget {
  const _FullRewards({
    required this.pointRewards,
    required this.gifts,
    required this.showHeader,
  });

  final int pointRewards;
  final List<String> gifts;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0FDF4), Color(0xFFFFFBEB)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phần thưởng',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        'Hoàn thành thử thách để nhận',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          if (pointRewards > 0) _PointsRewardCard(points: pointRewards),
          if (pointRewards > 0 && gifts.isNotEmpty) const SizedBox(height: 12),
          if (gifts.isNotEmpty) ...[
            const Text(
              'Quà tặng kèm theo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final useGrid = gifts.length <= 2 && constraints.maxWidth > 280;
                if (useGrid) {
                  return Row(
                    children: [
                      for (var i = 0; i < gifts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: _GiftRewardCard(gift: gifts[i])),
                      ],
                    ],
                  );
                }
                return SizedBox(
                  height: 108,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: gifts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      width: 132,
                      child: _GiftRewardCard(gift: gifts[index]),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PointsRewardCard extends StatelessWidget {
  const _PointsRewardCard({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const Text(
                  'điểm SYNC',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDCFCE7)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Điểm thưởng',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftRewardCard extends StatelessWidget {
  const _GiftRewardCard({required this.gift, this.compact = false});

  final String gift;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = _themeForGift(gift);

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: theme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(theme.icon, color: theme.accent, size: compact ? 16 : 18),
              ),
              const Spacer(),
              Text(theme.emoji, style: TextStyle(fontSize: compact ? 16 : 18)),
            ],
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            theme.category,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            gift,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 12 : 13,
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

class _CompactRewards extends StatelessWidget {
  const _CompactRewards({
    required this.pointRewards,
    required this.gifts,
  });

  final int pointRewards;
  final List<String> gifts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, size: 18, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            const Text(
              'Phần thưởng',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pointRewards > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lightGreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 18, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  '$pointRewards điểm SYNC',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
        if (pointRewards > 0 && gifts.isNotEmpty) const SizedBox(height: 8),
        if (gifts.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              if (gifts.length <= 2 && constraints.maxWidth > 240) {
                return Row(
                  children: [
                    for (var i = 0; i < gifts.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _GiftRewardCard(gift: gifts[i], compact: true)),
                    ],
                  ],
                );
              }

              return SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: gifts.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => SizedBox(
                    width: 120,
                    child: _GiftRewardCard(gift: gifts[index], compact: true),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _InlineRewards extends StatelessWidget {
  const _InlineRewards({
    required this.pointRewards,
    required this.gifts,
  });

  final int pointRewards;
  final List<String> gifts;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (pointRewards > 0)
          _InlineChip(
            label: '$pointRewards điểm',
            background: AppColors.lightGreen,
            foreground: AppColors.primaryGreen,
            icon: Icons.stars_rounded,
          ),
        ...gifts.map((gift) {
          final theme = _themeForGift(gift);
          return _InlineChip(
            label: gift,
            background: theme.background,
            foreground: theme.accent,
            icon: theme.icon,
          );
        }),
      ],
    );
  }
}

class _InlineChip extends StatelessWidget {
  const _InlineChip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: foreground),
          ),
        ],
      ),
    );
  }
}
