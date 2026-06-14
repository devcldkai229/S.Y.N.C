import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_mock.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_banner.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_coach_banner.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_phase_card.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_readiness_gauge.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_session_timeline_item.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_banner_carousel.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_display_helpers.dart';

class AiRoadmapTabView extends StatefulWidget {
  const AiRoadmapTabView({super.key, this.repository = const MockAiRoadmapRepository()});

  final AiRoadmapRepository repository;

  @override
  State<AiRoadmapTabView> createState() => _AiRoadmapTabViewState();
}

class _AiRoadmapTabViewState extends State<AiRoadmapTabView> {
  AiRoadmapSnapshot? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await widget.repository.loadSnapshot();
      if (!mounted) return;
      setState(() {
        _data = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không thể tải lộ trình. Thử lại nhé.';
      });
    }
  }

  AiRoadmapSessionVisual _visualFor(AiRoadmapSessionEntry entry) {
    if (entry.session.isCompleted) return AiRoadmapSessionVisual.completed;
    if (entry.isNextUp) return AiRoadmapSessionVisual.nextUp;
    return AiRoadmapSessionVisual.upcoming;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) {
      return const AiRoadmapSkeleton();
    }

    if (_error != null && _data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _load,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final snapshot = _data!;
    final roadmap = snapshot.roadmap;
    final recovery = snapshot.recovery;
    final coachMsg = AiRoadmapDisplayHelpers.coachTipMessage(recovery.recommendedTrainingIntensity);

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          const AiRoadmapBanner(),
          const SizedBox(height: 14),
          AiRoadmapPhaseCard(
            phaseTitle: roadmap.currentPhase.isNotEmpty ? roadmap.currentPhase : roadmap.roadmapName,
            currentWeek: snapshot.currentWeek,
            totalWeeks: snapshot.totalWeeks,
            fitnessGoal: roadmap.fitnessGoal,
            currentWeightKg: roadmap.currentWeightKg,
            targetWeightKg: roadmap.targetWeightKg,
            progressPercent: snapshot.progressPercent,
          ),
          const SizedBox(height: 14),
          AiRoadmapReadinessGauge(
            recoveryScore: recovery.currentRecoveryScore,
            fatigueLevel: recovery.fatigueLevel,
            sorenessScore: recovery.muscleSorenessScore,
            cnsFatigueScore: snapshot.cnsFatigueScore,
          ),
          const SizedBox(height: 12),
          AiRoadmapCoachBanner(message: coachMsg),
          const SizedBox(height: 22),
          const Text(
            'LỊCH TẬP TUẦN NÀY',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: WorkoutTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ...snapshot.weekSessions.map(
            (e) => AiRoadmapSessionTimelineItem(entry: e, visual: _visualFor(e)),
          ),
          const SizedBox(height: 20),
          const WorkoutBannerCarousel(),
        ],
      ),
    );
  }
}

class AiRoadmapSkeleton extends StatelessWidget {
  const AiRoadmapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget block({double height = 88}) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: WorkoutTheme.border.withValues(alpha: 0.45),
            borderRadius: WorkoutTheme.radiusMd,
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        block(height: 48),
        block(height: 160),
        block(height: 140),
        block(height: 56),
        block(height: 72),
        block(height: 72),
      ],
    );
  }
}
