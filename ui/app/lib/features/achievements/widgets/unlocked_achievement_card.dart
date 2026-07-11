import 'package:flutter/material.dart';
import 'package:sync_app/features/achievements/models/achievement_display_data.dart';
import 'package:sync_app/features/achievements/widgets/achievements_theme.dart';

class UnlockedAchievementCard extends StatelessWidget {
  const UnlockedAchievementCard({
    super.key,
    required this.achievement,
  });

  final UnlockedAchievement achievement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AchievementsTheme.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AchievementsTheme.goldCardShadow,
        border: Border.all(
          color: AchievementsTheme.goldGradientStart.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AchievementsTheme.goldGradientStart,
                  AchievementsTheme.goldGradientEnd,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AchievementsTheme.goldGradientStart.withValues(alpha: 0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AchievementsTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AchievementsTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
