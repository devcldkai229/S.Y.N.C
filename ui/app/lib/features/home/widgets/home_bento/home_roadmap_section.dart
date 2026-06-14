import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeRoadmapSection extends StatelessWidget {
  const HomeRoadmapSection({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final progress = data.phaseProgress > 0 ? data.phaseProgress : 0.6;
    final percent = (progress * 100).round();
    final goalTag = _goalChipLabel(data.goalLabel);
    final footer = data.progressHint?.isNotEmpty == true
        ? data.progressHint!
        : 'Bạn đang đi đúng hướng. Duy trì thâm hụt calo!';

    return BentoCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Lộ trình của tôi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: HomeBentoColors.textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TIẾN ĐỘ',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: HomeBentoColors.textMuted,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: HomeBentoColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: HomeBentoColors.lightGreen,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fitness_center_rounded, size: 16, color: HomeBentoColors.primaryGreen),
                const SizedBox(width: 6),
                Text(
                  goalTag,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: HomeBentoColors.primaryGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _WeightProgressTrack(progress: progress),
          const SizedBox(height: 16),
          Center(
            child: Text(
              footer,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: HomeBentoColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _goalChipLabel(String? goal) {
    if (goal == null || goal.isEmpty) return 'Giảm cân (FatLoss)';
    final lower = goal.toLowerCase();
    if (lower.contains('fat') || lower.contains('weight') || lower.contains('giảm')) {
      return 'Giảm cân (FatLoss)';
    }
    return goal;
  }
}

class _WeightProgressTrack extends StatelessWidget {
  const _WeightProgressTrack({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _EndpointLabel(
                top: 'BẮT ĐẦU',
                bottom: '75kg',
                centered: true,
              ),
            ),
            Expanded(
              flex: 3,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final thumbX = constraints.maxWidth * progress.clamp(0.08, 0.92);
                  return Column(
                    children: [
                      SizedBox(
                        height: 28,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              top: 12,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE5E7EB),
                                  color: HomeBentoColors.primaryGreen,
                                ),
                              ),
                            ),
                            Positioned(
                              left: thumbX - 10,
                              top: 4,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: HomeBentoColors.primaryGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Hiện tại: 72kg',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: HomeBentoColors.textPrimary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Expanded(
              child: _EndpointLabel(
                top: 'MỤC TIÊU',
                bottom: '70kg',
                centered: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EndpointLabel extends StatelessWidget {
  const _EndpointLabel({
    required this.top,
    required this.bottom,
    this.centered = false,
  });

  final String top;
  final String bottom;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final crossAlign =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          top,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: HomeBentoColors.textMuted,
            letterSpacing: 0.4,
            height: 1.3,
          ),
        ),
        Text(
          bottom,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: HomeBentoColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
