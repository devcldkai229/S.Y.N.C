import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class HomeDashboardData {
  HomeDashboardData({
    required this.greetingName,
    required this.subtitle,
    this.phaseLabel,
    this.weekLabel,
    this.goalLabel,
    this.phaseProgress = 0,
    this.progressHint,
    this.recoveryScore,
    this.recoveryHint,
    this.todaySessionTitle,
    this.todaySessionTime,
    this.todaySessionMeta,
    this.sessionIntensityBars = 0,
    this.syncCoins = 0,
    this.subscriptionTier = 'Free',
    this.walletHint,
  });

  final String greetingName;
  final String subtitle;
  final String? phaseLabel;
  final String? weekLabel;
  final String? goalLabel;
  final double phaseProgress;
  final String? progressHint;
  final int? recoveryScore;
  final String? recoveryHint;
  final String? todaySessionTitle;
  final String? todaySessionTime;
  final String? todaySessionMeta;
  final int sessionIntensityBars;
  final double syncCoins;
  final String subscriptionTier;
  final String? walletHint;

  factory HomeDashboardData.fromApi({
    required ProfileSettings settings,
    UserInventory? inventory,
    PersonalizedRoadmap? roadmap,
    List<RoadmapSession> sessions = const [],
    RecoveryProfile? recovery,
  }) {
    final name = settings.basic.fullName.split(' ').first;
    final phase = roadmap?.currentPhase ?? 'Your training plan';
    final goal = roadmap?.fitnessGoal ?? settings.fitness.fitnessGoal ?? 'Build strength';

    int week = 1;
    int totalWeeks = 6;
    if (roadmap != null) {
      week = DateTime.now().difference(roadmap.startDate).inDays ~/ 7 + 1;
      if (roadmap.expectedEndDate != null) {
        totalWeeks = (roadmap.expectedEndDate!.difference(roadmap.startDate).inDays / 7)
            .ceil()
            .clamp(1, 52);
      }
    }

    final progress = sessions.isEmpty
        ? 0.0
        : sessions.where((s) => s.isCompleted).length / sessions.length;

    RoadmapSession? todaySession;
    final now = DateTime.now();
    for (final s in sessions) {
      if (!s.isCompleted && s.scheduledDate.isAfter(now.subtract(const Duration(days: 1)))) {
        todaySession = s;
        break;
      }
    }
    todaySession ??= sessions.isNotEmpty ? sessions.first : null;

    final recoveryScore = recovery?.currentRecoveryScore;
    final recoveryHint = recovery != null
        ? (recoveryScore != null && recoveryScore >= 70
            ? 'Primed for high volume today.'
            : recovery.recommendedTrainingIntensity.isNotEmpty
                ? recovery.recommendedTrainingIntensity
                : 'Listen to your body today.')
        : null;

    final coins = inventory?.gamification?.syncCoins ?? 0;
    final tier = settings.basic.subscriptionTier;

    return HomeDashboardData(
      greetingName: name.isEmpty ? 'Athlete' : name,
      subtitle: 'Ready to conquer $phase.',
      phaseLabel: phase,
      weekLabel: 'Week $week of $totalWeeks',
      goalLabel: goal,
      phaseProgress: progress,
      progressHint: progress >= 0.5
          ? 'Consistent overload achieved. Keep pushing.'
          : 'Stay consistent to unlock the next phase.',
      recoveryScore: recoveryScore,
      recoveryHint: recoveryHint,
      todaySessionTitle: todaySession?.sessionTitle,
      todaySessionTime: todaySession?.scheduledTimeLabel,
      todaySessionMeta: todaySession != null
          ? '${todaySession.estimatedDurationMinutes} Min • ${todaySession.energyDemandLabel}'
          : null,
      sessionIntensityBars: _intensityBars(todaySession?.energyDemandLabel),
      syncCoins: coins,
      subscriptionTier: tier.isEmpty ? 'Free' : tier,
      walletHint: todaySession != null
          ? "Earn coins upon completing today's session."
          : 'Complete workouts to earn Sync Coins.',
    );
  }

  static int _intensityBars(String? demand) {
    if (demand == null) return 2;
    if (demand.toLowerCase().contains('extreme')) return 4;
    if (demand.toLowerCase().contains('high')) return 3;
    if (demand.toLowerCase().contains('moderate')) return 2;
    return 1;
  }
}

extension on RoadmapSession {
  String get scheduledTimeLabel {
    final t = scheduledDate.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
