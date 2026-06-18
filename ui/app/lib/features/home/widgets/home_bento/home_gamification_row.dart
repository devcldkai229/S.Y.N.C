import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeGamificationRow extends StatelessWidget {
  const HomeGamificationRow({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final streak = data.currentStreak > 0 ? data.currentStreak : 5;
    final coins = data.syncCoins > 0 ? data.syncCoins.round() : 500;

    return Row(
      children: [
        Expanded(
          child: _ForestCard(
            topIcon: Icons.local_fire_department_rounded,
            topLabel: 'CHUỖI $streak NGÀY',
            bottomText: 'Vượt trội',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ForestCard(
            topIcon: Icons.monetization_on_rounded,
            topLabel: '$coins COINS',
            bottomText: 'Tích lũy SYNC',
          ),
        ),
      ],
    );
  }
}

class _ForestCard extends StatelessWidget {
  const _ForestCard({
    required this.topIcon,
    required this.topLabel,
    required this.bottomText,
  });

  final IconData topIcon;
  final String topLabel;
  final String bottomText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeBentoColors.forestGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(topIcon, color: HomeBentoColors.limeChip, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  topLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            bottomText,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
