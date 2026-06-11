import 'package:flutter/material.dart';
import 'package:sync_app/features/achievements/widgets/achievements_theme.dart';

class AchievementsSectionHeader extends StatelessWidget {
  const AchievementsSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onSeeMore,
  });

  final String title;
  final String? trailing;
  final VoidCallback? onSeeMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AchievementsTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (onSeeMore != null)
            TextButton(
              onPressed: onSeeMore,
              style: TextButton.styleFrom(
                foregroundColor: AchievementsTheme.progress,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Xem thêm',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            )
          else if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AchievementsTheme.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}
