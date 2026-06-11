import 'package:flutter/material.dart';
import 'package:sync_app/features/achievements/models/achievement_display_data.dart';
import 'package:sync_app/features/achievements/widgets/achievements_theme.dart';

/// Slide-in stats panel (used inside a Stack — not Scaffold.drawer).
class AchievementsStatsPanel extends StatelessWidget {
  const AchievementsStatsPanel({
    super.key,
    this.stats = UserStatsDisplay.demo,
    required this.onClose,
  });

  final UserStatsDisplay stats;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatRow(Icons.military_tech_rounded, 'Level', '${stats.level}', const [Color(0xFF6366F1), Color(0xFF818CF8)]),
      _StatRow(Icons.bolt_rounded, 'XP', '${stats.xp}', const [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
      _StatRow(Icons.local_fire_department_rounded, 'Streak', '${stats.streakDays}d', const [Color(0xFFF97316), Color(0xFFFB923C)]),
      _StatRow(Icons.paid_rounded, 'Coins', '${stats.coins}', const [Color(0xFF10B981), Color(0xFF34D399)]),
      _StatRow(Icons.emoji_events_rounded, 'Points', '${stats.points}', const [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
    ];

    return Material(
      elevation: 16,
      shadowColor: Colors.black26,
      color: AchievementsTheme.card,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AchievementsTheme.textPrimary,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tổng quan gamification',
                          style: TextStyle(
                            fontSize: 13,
                            color: AchievementsTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: AchievementsTheme.textMuted,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 20, endIndent: 20),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _StatListTile(item: items[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow {
  const _StatRow(this.icon, this.label, this.value, this.gradient);

  final IconData icon;
  final String label;
  final String value;
  final List<Color> gradient;
}

class _StatListTile extends StatelessWidget {
  const _StatListTile({required this.item});

  final _StatRow item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: item.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: item.gradient.first.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(item.icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AchievementsTheme.textSecondary,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              item.value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AchievementsTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
