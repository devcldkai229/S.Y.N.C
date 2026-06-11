import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomePremiumCard extends StatelessWidget {
  const HomePremiumCard({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final tier = data.subscriptionTier.isNotEmpty ? data.subscriptionTier : 'Premium';
    final plan = data.phaseLabel?.isNotEmpty == true
        ? data.phaseLabel!.toUpperCase()
        : 'FOUNDATION PLAN';

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        onTap: () => context.push(AppRoutes.subscription),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HomeBentoColors.forestGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.workspace_premium_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          'Gói hội viên: $tier',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: HomeBentoColors.textPrimary,
          ),
        ),
        subtitle: Text(
          plan,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: HomeBentoColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: HomeBentoColors.textMuted,
        ),
      ),
    );
  }
}
