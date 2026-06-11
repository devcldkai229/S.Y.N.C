import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeChallengesSection extends StatelessWidget {
  const HomeChallengesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Thử thách đã đăng ký',
          trailing: TextButton(
            onPressed: () => context.push(AppRoutes.challengesMap),
            style: TextButton.styleFrom(
              foregroundColor: HomeBentoColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'XEM TẤT CẢ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _ActiveChallengeHeroCard(),
      ],
    );
  }
}

class _ActiveChallengeHeroCard extends StatelessWidget {
  const _ActiveChallengeHeroCard();

  @override
  Widget build(BuildContext context) {
    const currentDay = 15;
    const totalDays = 30;
    const progress = currentDay / totalDays;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.challengesMap),
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://picsum.photos/seed/sync-gym-workout/800/400',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: HomeBentoColors.forestGreen,
                child: const Center(
                  child: Icon(Icons.fitness_center_rounded, color: Colors.white54, size: 48),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: HomeBentoColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ĐANG DIỄN RA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: HomeBentoColors.primaryGreen,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    '30 Ngày Bứt Phá Cơ Bụng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hoàn thành: $currentDay/$totalDays ngày',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
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
    );
  }
}
