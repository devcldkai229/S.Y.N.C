import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeLevelCard extends StatelessWidget {
  const HomeLevelCard({super.key, required this.data});

  final HomeDashboardData data;

  static const _xpPerLevel = 2000;

  @override
  Widget build(BuildContext context) {
    final level = data.currentLevel > 1 ? data.currentLevel : 12;
    final xpInLevel = data.currentXp > 0 ? (data.currentXp % _xpPerLevel) : 1250;
    final progress = (xpInLevel / _xpPerLevel).clamp(0.0, 1.0);

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'CẤP ĐỘ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: HomeBentoColors.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HomeBentoColors.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: HomeBentoColors.primaryGreen,
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$level',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              color: HomeBentoColors.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$xpInLevel XP / $_xpPerLevel XP',
            style: const TextStyle(
              fontSize: 12,
              color: HomeBentoColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
