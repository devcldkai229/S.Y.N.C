import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeScheduleSection extends StatelessWidget {
  const HomeScheduleSection({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final title = data.todaySessionTitle ?? 'Demo Pull & Core';
    final time = data.todaySessionTime ?? '07:00';
    final duration = _durationLabel(data.todaySessionMeta) ?? '40 Phút';
    final intensityLabel = _intensityLabel(data.sessionIntensityBars);
    final bars = data.sessionIntensityBars > 0 ? data.sessionIntensityBars : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'Lịch trình hôm nay',
          trailing: const Icon(
            Icons.calendar_today_outlined,
            size: 22,
            color: HomeBentoColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: HomeBentoColors.lightGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: HomeBentoColors.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: HomeBentoColors.primaryGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: HomeBentoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$duration • $intensityLabel',
                      style: const TextStyle(
                        fontSize: 14,
                        color: HomeBentoColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Intensity',
                          style: TextStyle(
                            fontSize: 11,
                            color: HomeBentoColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: HomeBentoColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        _IntensityBars(filled: bars),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  const SizedBox(height: 24),
                  Material(
                    color: HomeBentoColors.primaryGreen,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 2,
                    shadowColor: HomeBentoColors.primaryGreen.withValues(alpha: 0.4),
                    child: InkWell(
                      onTap: () => context.go(AppRoutes.workouts),
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.add_rounded, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String? _durationLabel(String? meta) {
    if (meta == null || meta.isEmpty) return null;
    final match = RegExp(r'(\d+)\s*Min').firstMatch(meta);
    if (match != null) return '${match.group(1)} Phút';
    return null;
  }

  static String _intensityLabel(int bars) {
    return switch (bars) {
      >= 4 => 'Cao',
      3 => 'Khá cao',
      2 => 'Trung bình',
      _ => 'Nhẹ',
    };
  }
}

class _IntensityBars extends StatelessWidget {
  const _IntensityBars({required this.filled});

  final int filled;

  @override
  Widget build(BuildContext context) {
    const heights = [14.0, 11.0, 8.0, 6.0];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < filled.clamp(0, 4);
        return Container(
          width: 5,
          height: heights[i],
          margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
          decoration: BoxDecoration(
            color: active ? HomeBentoColors.primaryGreen : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
