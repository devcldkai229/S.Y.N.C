import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/data/home_display_helpers.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class MembershipPill extends StatelessWidget {
  const MembershipPill({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final tier = HomeDisplayHelpers.subscriptionTierVi(data.subscriptionTier);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(AppRoutes.subscription),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: HomeBentoColors.card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.workspace_premium_outlined,
                  size: 18,
                  color: HomeBentoColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gói $tier',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HomeBentoColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  '·',
                  style: TextStyle(color: HomeBentoColors.textMuted),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Nâng cấp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: HomeBentoColors.primaryGreen,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: HomeBentoColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
