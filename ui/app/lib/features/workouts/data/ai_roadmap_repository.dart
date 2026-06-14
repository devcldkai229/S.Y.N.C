import 'package:sync_app/features/workouts/models/workout_models.dart';

/// UI snapshot for AI Roadmap tab — decoupled from API shape.
class AiRoadmapSnapshot {
  const AiRoadmapSnapshot({
    required this.roadmap,
    required this.recovery,
    required this.weekSessions,
    required this.progressPercent,
    required this.currentWeek,
    required this.totalWeeks,
    this.cnsFatigueScore,
  });

  final PersonalizedRoadmap roadmap;
  final RecoveryProfile recovery;
  final List<AiRoadmapSessionEntry> weekSessions;
  final int progressPercent;
  final int currentWeek;
  final int totalWeeks;
  final int? cnsFatigueScore;
}

class AiRoadmapSessionEntry {
  const AiRoadmapSessionEntry({
    required this.session,
    required this.energyDemandScore,
    this.isNextUp = false,
  });

  final RoadmapSession session;
  final int energyDemandScore;
  final bool isNextUp;
}

abstract class AiRoadmapRepository {
  Future<AiRoadmapSnapshot> loadSnapshot();
}
