import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/services/workout_api_service.dart';

class WorkoutRepository {
  WorkoutRepository(this._api);

  final WorkoutApiService _api;

  Future<({PersonalizedRoadmap? roadmap, List<RoadmapSession> sessions, RecoveryProfile? recovery})>
      loadRoadmap() async {
    final roadmaps = await _api.getRoadmaps();
    PersonalizedRoadmap? active;
    for (final r in roadmaps) {
      if (r.roadmapStatus.toLowerCase().contains('active')) {
        active = r;
        break;
      }
    }
    active ??= roadmaps.isNotEmpty ? roadmaps.first : null;

    if (active == null) {
      return (roadmap: null, sessions: <RoadmapSession>[], recovery: null);
    }

    final sessions = await _api.getSessions(roadmapId: active.id, pageSize: 30);
    sessions.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
    final recovery = await _api.getLatestRecoveryProfile();
    return (roadmap: active, sessions: sessions, recovery: recovery);
  }

  Future<List<ExerciseCatalogItem>> searchCatalog({
    String? query,
    String? category,
  }) =>
      _api.searchExercises(
        query: query,
        category: category == 'All' ? null : category,
        pageSize: 80,
      );
}
