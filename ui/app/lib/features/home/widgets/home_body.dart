import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';
import 'package:sync_app/features/home/widgets/home_redesign/gamification_strip.dart';
import 'package:sync_app/features/home/widgets/home_redesign/home_banner_carousel.dart';
import 'package:sync_app/features/home/widgets/home_redesign/home_challenges_row.dart';
import 'package:sync_app/features/home/widgets/home_redesign/home_greeting_line.dart';
import 'package:sync_app/features/home/widgets/home_redesign/home_shortcut_row.dart';
import 'package:sync_app/features/home/widgets/home_redesign/membership_pill.dart';
import 'package:sync_app/features/home/widgets/home_redesign/roadmap_progress_card.dart';
import 'package:sync_app/features/home/widgets/home_redesign/today_hero_carousel.dart';

/// Scrollable home content. AppBar and bottom nav are owned by parent.
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
          HomeGreetingLine(data: data),
          const SizedBox(height: 14),
          GamificationStrip(data: data),
          const SizedBox(height: 16),
          TodayHeroCarousel(data: data),
          const SizedBox(height: 16),
          RoadmapProgressCard(data: data),
          const SizedBox(height: 20),
          const HomeBannerCarousel(),
          const SizedBox(height: 20),
          const HomeChallengesRow(),
          const SizedBox(height: 20),
          const HomeShortcutRow(),
          const SizedBox(height: 16),
          MembershipPill(data: data),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

Color get homeBodyBackground => HomeBentoColors.background;
