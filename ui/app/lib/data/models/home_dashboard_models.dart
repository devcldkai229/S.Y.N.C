import 'package:sync_app/features/home/data/home_display_helpers.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class HomeDashboardData {
  HomeDashboardData({
    required this.greetingName,
    this.phaseLabel,
    this.weekLabel,
    this.goalLabel,
    this.phaseProgress = 0,
    this.progressHint,
    this.recoveryScore,
    this.recoveryHint,
    this.todaySessionId,
    this.todaySessionTitle,
    this.todaySessionTime,
    this.todaySessionMeta,
    this.todaySessionExerciseCount = 0,
    this.todaySessionDurationMinutes,
    this.sessionIntensityBars = 0,
    this.syncCoins = 0,
    this.subscriptionTier = 'Free',
    this.currentWeightKg,
    this.targetWeightKg,
    this.startWeightKg,
    this.currentLevel = 1,
    this.currentXp = 0,
    this.currentStreak = 0,
  });

  final String greetingName;
  final String? phaseLabel;
  final String? weekLabel;
  final String? goalLabel;
  final double phaseProgress;
  final String? progressHint;
  final int? recoveryScore;
  final String? recoveryHint;
  final String? todaySessionId;
  final String? todaySessionTitle;
  final String? todaySessionTime;
  final String? todaySessionMeta;
  final int todaySessionExerciseCount;
  final int? todaySessionDurationMinutes;
  final int sessionIntensityBars;
  final double syncCoins;
  final String subscriptionTier;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? startWeightKg;
  final int currentLevel;
  final int currentXp;
  final int currentStreak;

  int get xpInLevel => currentXp % HomeDisplayHelpers.xpPerLevel;

  double get xpProgress =>
      (xpInLevel / HomeDisplayHelpers.xpPerLevel).clamp(0.0, 1.0);

  factory HomeDashboardData.fromApi({
    required ProfileSettings settings,
    UserInventory? inventory,
    PersonalizedRoadmap? roadmap,
    List<RoadmapSession> sessions = const [],
    RecoveryProfile? recovery,
  }) {
    final name = settings.basic.fullName.split(' ').first;
    final phase = HomeDisplayHelpers.phaseVi(roadmap?.currentPhase);
    final goal = HomeDisplayHelpers.fitnessGoalVi(
      roadmap?.fitnessGoal ?? settings.fitness.fitnessGoal,
    );

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
    todaySession ??= sessions.cast<RoadmapSession?>().firstWhere(
          (s) => s != null && !s.isCompleted,
          orElse: () => sessions.isNotEmpty ? sessions.first : null,
        );

    final recoveryScore = recovery?.currentRecoveryScore;
    final recoveryHint = recovery != null
        ? HomeDisplayHelpers.recoveryHintVi(
            recoveryScore,
            recovery.recommendedTrainingIntensity,
          )
        : null;

    final gamification = inventory?.gamification;
    final coins = gamification?.syncCoins ?? 0;
    final tier = settings.basic.subscriptionTier;

    final currentWeight = settings.fitness.currentWeightKg ?? 72;
    final targetWeight = settings.fitness.targetWeightKg ?? 70;
    final startWeight = HomeDisplayHelpers.estimateStartWeight(
          current: currentWeight,
          target: targetWeight,
          progress: progress > 0 ? progress : 0.5,
        ) ??
        75;

    final durationMinutes = todaySession?.estimatedDurationMinutes;
    final exerciseCount = todaySession?.exerciseCount ?? 0;

    return HomeDashboardData(
      greetingName: name.isEmpty ? 'Bạn' : name,
      phaseLabel: phase,
      weekLabel: HomeDisplayHelpers.weekLabelVi(week, totalWeeks),
      goalLabel: goal,
      phaseProgress: progress,
      progressHint: HomeDisplayHelpers.progressHintVi(progress),
      recoveryScore: recoveryScore,
      recoveryHint: recoveryHint,
      todaySessionId: todaySession?.id,
      todaySessionTitle: todaySession?.sessionTitle ?? 'Buổi tập hôm nay',
      todaySessionTime: todaySession?.scheduledTimeLabel,
      todaySessionMeta: todaySession != null
          ? '${durationMinutes ?? 40} phút • ${exerciseCount > 0 ? '$exerciseCount bài' : 'AI gợi ý'}'
          : null,
      todaySessionExerciseCount: exerciseCount,
      todaySessionDurationMinutes: durationMinutes,
      sessionIntensityBars: todaySession != null
          ? _intensityBarsFromSession(todaySession)
          : 2,
      syncCoins: coins,
      subscriptionTier: tier.isEmpty ? 'Free' : tier,
      currentWeightKg: currentWeight,
      targetWeightKg: targetWeight,
      startWeightKg: startWeight,
      currentLevel: gamification?.currentLevel ?? 1,
      currentXp: gamification?.currentXp ?? 0,
      currentStreak: gamification?.currentStreak ?? 0,
    );
  }

  static int _intensityBarsFromSession(RoadmapSession session) {
    final type = session.sessionType.toLowerCase();
    if (type.contains('hiit') || type.contains('cardio')) return 4;
    if (type.contains('strength') || type.contains('power')) return 3;
    if (type.contains('mobility') || type.contains('recovery')) return 1;
    if (session.estimatedDurationMinutes >= 60) return 4;
    if (session.estimatedDurationMinutes >= 40) return 3;
    return 2;
  }
}

extension on RoadmapSession {
  String get scheduledTimeLabel {
    if (scheduledTime.isNotEmpty) return scheduledTime;
    final t = scheduledDate.toLocal();
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
