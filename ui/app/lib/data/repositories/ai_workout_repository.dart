import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/services/ai_workout_api_service.dart';

/// Thin wrapper around [AiWorkoutApiService] for the AI generate / swap features.
class AiWorkoutRepository {
  AiWorkoutRepository(this._api);

  final AiWorkoutApiService _api;

  Future<AiGeneratedSession> generateSessionExercises({
    required String goal,
    required String sessionTitle,
    String? targetMuscleGroup,
    int desiredExerciseCount = 6,
    List<String> excludeCodes = const [],
  }) =>
      _api.generateSessionExercises(
        goal: goal,
        sessionTitle: sessionTitle,
        targetMuscleGroup: targetMuscleGroup,
        desiredExerciseCount: desiredExerciseCount,
        excludeCodes: excludeCodes,
      );

  Future<AiSuggestedExercise> swapExercise({
    required String currentExerciseCode,
    String? goal,
    String? sessionTitle,
    List<String> excludeCodes = const [],
  }) =>
      _api.swapExercise(
        currentExerciseCode: currentExerciseCode,
        goal: goal,
        sessionTitle: sessionTitle,
        excludeCodes: excludeCodes,
      );
}
