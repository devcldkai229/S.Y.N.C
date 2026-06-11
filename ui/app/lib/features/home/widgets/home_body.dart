import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_challenges_section.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_gamification_row.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_level_card.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_premium_card.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_roadmap_section.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_schedule_section.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_welcome_section.dart';

/// Scrollable Bento-grid home content. AppBar and bottom nav are owned by parent.
class HomeBody extends StatelessWidget {
  const HomeBody({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeWelcomeSection(data: data),
          const SizedBox(height: 16),
          HomeLevelCard(data: data),
          const SizedBox(height: 16),
          HomeGamificationRow(data: data),
          const SizedBox(height: 16),
          HomePremiumCard(data: data),
          const SizedBox(height: 16),
          HomeRoadmapSection(data: data),
          const SizedBox(height: 16),
          const HomeChallengesSection(),
          const SizedBox(height: 16),
          HomeScheduleSection(data: data),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

Color get homeBodyBackground => HomeBentoColors.background;
