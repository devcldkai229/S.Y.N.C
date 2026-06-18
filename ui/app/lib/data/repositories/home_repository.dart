import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/services/workout_api_service.dart';

class HomeRepository {
  HomeRepository(this._profileApi, this._workoutApi);

  final ProfileApiService _profileApi;
  final WorkoutApiService _workoutApi;

  Future<HomeDashboardData> loadDashboard() async {
    ProfileSettings settings;
    try {
      settings = await _profileApi.getProfileSettings();
    } catch (_) {
      settings = ProfileSettings.fromJson(const {});
    }

    UserInventory? inventory;
    try {
      inventory = await _profileApi.getInventory();
    } catch (_) {}

    var roadmaps = <PersonalizedRoadmap>[];
    try {
      roadmaps = await _workoutApi.getRoadmaps();
    } catch (_) {}

    PersonalizedRoadmap? active;
    for (final r in roadmaps) {
      if (r.isActive) {
        active = r;
        break;
      }
    }
    active ??= roadmaps.isNotEmpty ? roadmaps.first : null;

    var sessions = <RoadmapSession>[];
    RecoveryProfile? recovery;
    if (active != null) {
      try {
        sessions = await _workoutApi.getSessions(roadmapId: active.id, pageSize: 20);
      } catch (_) {}
      try {
        recovery = await _workoutApi.getLatestRecoveryProfile();
      } catch (_) {}
    }

    return HomeDashboardData.fromApi(
      settings: settings,
      inventory: inventory,
      roadmap: active,
      sessions: sessions,
      recovery: recovery,
    );
  }
}
