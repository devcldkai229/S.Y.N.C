import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/data/home_display_helpers.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class RoadmapProgressCard extends StatelessWidget {
  const RoadmapProgressCard({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.phaseProgress > 0 ? data.phaseProgress : 0.5;
    final percent = (progress * 100).round();
    final goal = data.goalLabel ?? 'Giảm cân';
    final current = data.currentWeightKg ?? 72;
    final target = data.targetWeightKg ?? 70;
    final start = data.startWeightKg ?? 75;
    final hint = data.progressHint ?? HomeDisplayHelpers.progressHintVi(progress);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(AppRoutes.workouts),
        borderRadius: BorderRadius.circular(16),
        child: BentoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(progress: progress, percent: percent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lộ trình của tôi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: HomeBentoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: HomeBentoColors.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        goal,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: HomeBentoColors.primaryGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _WeightBar(
                      start: start,
                      current: current,
                      target: target,
                      progress: progress,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: HomeBentoColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: HomeBentoColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress, required this.percent});

  final double progress;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 6,
                backgroundColor: const Color(0xFFE5E7EB),
                color: HomeBentoColors.primaryGreen,
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: HomeBentoColors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WeightBar extends StatelessWidget {
  const _WeightBar({
    required this.start,
    required this.current,
    required this.target,
    required this.progress,
  });

  final double start;
  final double current;
  final double target;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFFE5E7EB),
            color: HomeBentoColors.primaryGreen,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              HomeDisplayHelpers.weightLabel(start),
              style: const TextStyle(fontSize: 11, color: HomeBentoColors.textMuted),
            ),
            const Spacer(),
            Text(
              'Hiện tại: ${HomeDisplayHelpers.weightLabel(current)}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: HomeBentoColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              HomeDisplayHelpers.weightLabel(target),
              style: const TextStyle(fontSize: 11, color: HomeBentoColors.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
