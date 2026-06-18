import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/challenge_repository.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/widgets/challenge_background.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeChallengesRow extends StatefulWidget {
  const HomeChallengesRow({super.key});

  @override
  State<HomeChallengesRow> createState() => _HomeChallengesRowState();
}

class _HomeChallengesRowState extends State<HomeChallengesRow> {
  List<CommunityChallenge> _challenges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = getIt<ChallengeRepository>();
      final all = await repo.getChallenges(pageSize: 10);
      final visible = all
          .where((c) => c.status == 'InProgress' || c.status == 'Active' || c.status == 'Upcoming')
          .take(3)
          .toList();
      if (mounted) setState(() => _challenges = visible);
    } catch (_) {
      if (mounted) setState(() => _challenges = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Thử thách',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.challengesMap),
            style: TextButton.styleFrom(
              foregroundColor: HomeBentoColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Xem tất cả',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          const SizedBox(
            height: 168,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_challenges.isEmpty)
          SizedBox(
            height: 120,
            child: Center(
              child: Text(
                'Chưa có thử thách nào',
                style: TextStyle(color: HomeBentoColors.textPrimary.withValues(alpha: 0.5)),
              ),
            ),
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _challenges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = _challenges[index];
                return ChallengeCard(
                  title: c.title,
                  backgroundUrl: c.backgroundUrl,
                  progress: c.progressFraction,
                  progressLabel: c.homeProgressLabel,
                  badge: c.homeBadge,
                  onTap: () => context.push(AppRoutes.challengeDetail(c.id)),
                );
              },
            ),
          ),
      ],
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.title,
    required this.progress,
    required this.progressLabel,
    required this.badge,
    this.backgroundUrl,
    this.onTap,
  });

  final String title;
  final double progress;
  final String progressLabel;
  final String badge;
  final String? backgroundUrl;
  final VoidCallback? onTap;

  static const _cardWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _cardWidth,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ChallengeBackground(backgroundUrl: backgroundUrl),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HomeBentoColors.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: HomeBentoColors.primaryGreen,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progressLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
