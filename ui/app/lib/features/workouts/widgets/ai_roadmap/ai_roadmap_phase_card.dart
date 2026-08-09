import 'package:flutter/material.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/l10n/app_localizations.dart';

class AiRoadmapPhaseCard extends StatelessWidget {
  const AiRoadmapPhaseCard({super.key, required this.overview});

  final RoadmapOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';
    final goalLabel = _goalLabel(l10n, overview.fitnessGoal);
    final current = overview.progress.currentWeightKg;
    final target = overview.progress.targetWeightKg;
    final hasWeights = current != null && target != null && target > 0;
    final weightProgress = hasWeights
        ? (1.0 - ((current - target).abs() / 10.0)).clamp(0.05, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            WorkoutTheme.primary.withValues(alpha: 0.14),
            WorkoutTheme.lime.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: WorkoutTheme.radiusLg,
        border: Border.all(color: WorkoutTheme.primary.withValues(alpha: 0.18)),
        boxShadow: WorkoutTheme.cardShadow(opacity: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(l10n.aiRoadmapGoalChip(goalLabel)),
              _chip(l10n.aiRoadmapWeekOf(overview.currentWeek, overview.totalWeeks)),
            ],
          ),
          const SizedBox(height: 18),
          _PhaseStepper(phases: overview.phases, isVi: isVi),
          if (hasWeights) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.aiRoadmapWeightCurrent(current.toStringAsFixed(1)),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WorkoutTheme.forest),
                  ),
                ),
                Text(
                  l10n.aiRoadmapWeightTarget(target.toStringAsFixed(1)),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: WorkoutTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: weightProgress,
                minHeight: 8,
                backgroundColor: WorkoutTheme.border,
                color: WorkoutTheme.primary,
              ),
            ),
          ],
          if (overview.phaseRationale(isVi).isNotEmpty) ...[
            const SizedBox(height: 14),
            _WhyBox(title: l10n.aiRoadmapWhyTitle, body: overview.phaseRationale(isVi)),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WorkoutTheme.card.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: WorkoutTheme.primary),
      ),
    );
  }

  static String _goalLabel(AppLocalizations l10n, String goal) {
    final g = goal.toLowerCase();
    if (g.contains('fat') || g.contains('lose')) return l10n.aiRoadmapGoalFatLoss;
    if (g.contains('muscle') || g.contains('hypertrophy') || g.contains('build')) {
      return l10n.aiRoadmapGoalMuscleGain;
    }
    return l10n.aiRoadmapGoalGeneralHealth;
  }
}

class _PhaseStepper extends StatelessWidget {
  const _PhaseStepper({required this.phases, required this.isVi});

  final List<RoadmapPhaseOverview> phases;
  final bool isVi;

  @override
  Widget build(BuildContext context) {
    if (phases.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < phases.length; i++) ...[
              _dot(phases[i]),
              if (i < phases.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    color: phases[i].isDone || phases[i].isCurrent
                        ? WorkoutTheme.primary
                        : WorkoutTheme.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final p in phases)
              Expanded(
                child: Text(
                  p.displayName(isVi),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: p.isCurrent ? FontWeight.w900 : FontWeight.w600,
                    color: p.isCurrent ? WorkoutTheme.primary : WorkoutTheme.textMuted,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _dot(RoadmapPhaseOverview phase) {
    final active = phase.isCurrent || phase.isDone;
    return Container(
      width: phase.isCurrent ? 16 : 12,
      height: phase.isCurrent ? 16 : 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? WorkoutTheme.primary : WorkoutTheme.border,
        border: phase.isCurrent
            ? Border.all(color: WorkoutTheme.lime, width: 3)
            : null,
      ),
    );
  }
}

class _WhyBox extends StatelessWidget {
  const _WhyBox({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 20, color: WorkoutTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: WorkoutTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, height: 1.35, fontWeight: FontWeight.w600, color: WorkoutTheme.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
