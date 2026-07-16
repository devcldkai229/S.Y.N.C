import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/workouts/data/ai_roadmap_repository.dart';
import 'package:sync_app/features/workouts/models/roadmap_overview_models.dart';

class ApiAiRoadmapRepository implements AiRoadmapRepository {
  ApiAiRoadmapRepository({
    WorkoutRepository? workouts,
    ProfileApiService? profiles,
  })  : _workouts = workouts ?? getIt<WorkoutRepository>(),
        _profiles = profiles ?? getIt<ProfileApiService>();

  final WorkoutRepository _workouts;
  final ProfileApiService _profiles;

  @override
  Future<RoadmapOverview?> loadOverview() async {
    String? experience;
    try {
      final settings = await _profiles.getProfileSettings();
      experience = settings.fitness.fitnessExperienceLevel;
    } catch (_) {
      experience = null;
    }
    return _workouts.loadRoadmapOverview(experienceLevel: experience);
  }
}
