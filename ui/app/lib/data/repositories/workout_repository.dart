import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/services/workout_api_service.dart';

class WorkoutRepository {
  WorkoutRepository(this._api);

  final WorkoutApiService _api;

  /// Loads the active AI personalized roadmap, its sessions, and latest recovery.
  Future<({PersonalizedRoadmap? roadmap, List<RoadmapSession> sessions, RecoveryProfile? recovery})>
      loadRoadmap() async {
    final roadmaps = await _api.getRoadmaps();
    PersonalizedRoadmap? active;
    for (final r in roadmaps) {
      if (r.isActive) {
        active = r;
        break;
      }
    }
    active ??= roadmaps.isNotEmpty ? roadmaps.first : null;

    if (active == null) {
      final recovery = await _api.getLatestRecoveryProfile();
      return (roadmap: null, sessions: <RoadmapSession>[], recovery: recovery);
    }

    List<RoadmapSession> sessions;
    try {
      sessions = await _api.getSessionsByRoadmap(active.id);
    } catch (_) {
      sessions = await _api.getSessions(roadmapId: active.id);
    }
    sessions.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));

    final recovery = await _api.getLatestRecoveryProfile();
    return (roadmap: active, sessions: sessions, recovery: recovery);
  }

  Future<List<UserCustomWorkout>> loadCustomWorkouts() => _api.getCustomWorkouts();

  Future<UserCustomWorkout> createCustomWorkout(Map<String, dynamic> data) =>
      _api.createCustomWorkout(data);

  Future<UserCustomWorkout> getCustomWorkoutById(String id) =>
      _api.getCustomWorkoutById(id);

  Future<RoadmapSession> getSessionById(String id) =>
      _api.getSessionById(id);

  Future<Map<String, dynamic>> createRoadmapSession(Map<String, dynamic> data) =>
      _api.createRoadmapSession(data);

  Future<Map<String, dynamic>> createScheduledWorkout(Map<String, dynamic> data) =>
      _api.createScheduledWorkout(data);

  Future<List<ExerciseCatalogItem>> searchCatalog({
    String? query,
    String? category,
  }) =>
      _api.searchExercises(
        query: query,
        category: category == 'All' ? null : category,
        pageSize: 80,
      );

  Future<ExerciseCatalogDetail?> getExerciseDetail(String id) =>
      _api.getExerciseDetail(id);

  Future<List<RoadmapSession>> getSessionsByRoadmap(String roadmapId) =>
      _api.getSessionsByRoadmap(roadmapId);

  Future<MyWorkoutDetail> getCustomWorkoutDetail(String id) =>
      _api.getCustomWorkoutDetail(id);

  Future<UserCustomWorkout> updateCustomWorkout(String id, Map<String, dynamic> data) =>
      _api.updateCustomWorkout(id, data);

  Future<void> deleteCustomWorkout(String id) => _api.deleteCustomWorkout(id);

  Future<RoadmapSession> updateRoadmapSession(String sessionId, Map<String, dynamic> data) =>
      _api.updateRoadmapSession(sessionId, data);

  Future<WorkoutExecutionDetail> startWorkout(String sessionId, {int? energyLevelBefore}) =>
      _api.startWorkout(sessionId, energyLevelBefore: energyLevelBefore);

  Future<WorkoutExecutionSummary> finishWorkout(
    String executionId, {
    int? perceivedDifficulty,
    int? energyLevelAfter,
    String? sessionFeedback,
  }) =>
      _api.finishWorkout(
        executionId,
        perceivedDifficulty: perceivedDifficulty,
        energyLevelAfter: energyLevelAfter,
        sessionFeedback: sessionFeedback,
      );

  Future<void> cancelWorkout(String executionId) => _api.cancelWorkout(executionId);

  Future<ExerciseSetLog> createExerciseSetLog({
    required String executionId,
    required String exerciseId,
    required int setNumber,
    required int targetReps,
    required int actualReps,
    required double weightKg,
    required int rir,
    required int restTakenSeconds,
    required int formScore,
    required bool completed,
  }) =>
      _api.createExerciseSetLog(
        executionId: executionId,
        exerciseId: exerciseId,
        setNumber: setNumber,
        targetReps: targetReps,
        actualReps: actualReps,
        weightKg: weightKg,
        rir: rir,
        restTakenSeconds: restTakenSeconds,
        formScore: formScore,
        completed: completed,
      );
}
