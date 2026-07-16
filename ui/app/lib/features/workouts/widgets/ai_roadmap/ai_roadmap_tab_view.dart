import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_api_repository.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';
import 'package:sync_app/features/workouts/state/roadmap_refresh_notifier.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_banner.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_next_session_card.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_phase_card.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_readiness_gauge.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_session_timeline_item.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_banner_carousel.dart';

class AiRoadmapTabView extends StatefulWidget {
  const AiRoadmapTabView({super.key, this.repository});

  final AiRoadmapRepository? repository;

  @override
  State<AiRoadmapTabView> createState() => _AiRoadmapTabViewState();
}

class _AiRoadmapTabViewState extends State<AiRoadmapTabView> {
  late final AiRoadmapRepository _repository =
      widget.repository ?? ApiAiRoadmapRepository();
  late final RoadmapRefreshNotifier _refreshNotifier;

  RoadmapOverview? _data;
  bool _loading = true;
  bool _hasNoRoadmap = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshNotifier = getIt<RoadmapRefreshNotifier>();
    _refreshNotifier.addListener(_onRoadmapRealtime);
    _load();
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_onRoadmapRealtime);
    super.dispose();
  }

  void _onRoadmapRealtime() {
    if (!mounted) return;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasNoRoadmap = false;
    });
    try {
      final overview = await _repository.loadOverview();
      if (!mounted) return;
      if (overview == null) {
        setState(() {
          _hasNoRoadmap = true;
          _loading = false;
        });
      } else {
        setState(() {
          _data = overview;
          _hasNoRoadmap = false;
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.aiRoadmapLoadFailed;
      });
    }
  }

  void _navigateToCynForRoadmap() {
    context.push(AppRoutes.cynChat, extra: context.l10n.aiRoadmapEmptyAutoMessage);
  }

  void _askAiAboutSession(RoadmapSessionOverview session) {
    final name = Localizations.localeOf(context).languageCode == 'vi'
        ? session.displayNameVi
        : (session.subtitleEn.isNotEmpty ? session.subtitleEn : session.displayNameVi);
    context.push(AppRoutes.cynChat, extra: context.l10n.aiRoadmapAskAiPrompt(name));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (_loading && _data == null && !_hasNoRoadmap) {
      return const AiRoadmapSkeleton();
    }

    if (_hasNoRoadmap) {
      return _CynEmptyState(onStart: _navigateToCynForRoadmap);
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
                child: Text(l10n.aiRoadmapRetry),
              ),
            ],
          ),
        ),
      );
    }

    final overview = _data!;
    final next = overview.nextSession;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primaryGreen,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          const AiRoadmapBanner(),
          const SizedBox(height: 14),
          AiRoadmapPhaseCard(overview: overview),
          if (overview.readiness != null) ...[
            const SizedBox(height: 14),
            AiRoadmapReadinessGauge(readiness: overview.readiness!),
          ],
          if (next != null) ...[
            const SizedBox(height: 14),
            AiRoadmapNextSessionCard(
              session: next,
              onStart: () => context.push(AppRoutes.customSessionDetail(next.id)),
              onAskAi: () => _askAiAboutSession(next),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            l10n.aiRoadmapWeekSchedule.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: WorkoutTheme.textMuted),
          ),
          const SizedBox(height: 12),
          ...overview.sessions.map((s) => AiRoadmapSessionTimelineItem(session: s)),
          const SizedBox(height: 20),
          const WorkoutBannerCarousel(),
        ],
      ),
    );
  }
}

class _CynEmptyState extends StatefulWidget {
  const _CynEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  State<_CynEmptyState> createState() => _CynEmptyStateState();
}

class _CynEmptyStateState extends State<_CynEmptyState> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final scale = 1.0 + _pulseAnim.value * 0.08;
                final glowOpacity = 0.10 + _pulseAnim.value * 0.18;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFDEFF9A),
                          Color(0xFFA8E063),
                          AppColors.primaryGreen,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: glowOpacity),
                          blurRadius: 32,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 40, color: Colors.white),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              l10n.aiRoadmapEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.aiRoadmapEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: widget.onStart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.rocket_launch_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      l10n.aiRoadmapEmptyCta,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
        block(height: 180),
        block(height: 160),
        block(height: 200),
        block(height: 72),
        block(height: 72),
      ],
    );
  }
}
