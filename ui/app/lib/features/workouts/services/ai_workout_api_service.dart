import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

/// Result of an AI session generation: the suggested exercises plus the coach's
/// message/rationale to surface to the user.
class AiGeneratedSession {
  AiGeneratedSession({
    required this.exercises,
    required this.coachingMessage,
    required this.rationale,
  });

  final List<AiSuggestedExercise> exercises;
  final String coachingMessage;
  final String rationale;
}

/// Calls the AIAgent microservice (via the gateway) to generate / swap exercises.
class AiWorkoutApiService {
  AiWorkoutApiService(this._dio);

  final Dio _dio;

  Future<AiGeneratedSession> generateSessionExercises({
    required String goal,
    required String sessionTitle,
    String? targetMuscleGroup,
    int desiredExerciseCount = 6,
    List<String> excludeCodes = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.aiGenerateSessionExercises,
      data: {
        'goal': goal,
        'sessionTitle': sessionTitle,
        if (targetMuscleGroup != null && targetMuscleGroup.isNotEmpty)
          'targetMuscleGroup': targetMuscleGroup,
        'desiredExerciseCount': desiredExerciseCount,
        'excludeExerciseCodes': excludeCodes,
      },
    );
    final data = _unwrap(response.data, 'Tạo bài tập AI thất bại');
    final rawList = data['exercises'];
    final exercises = (rawList is List)
        ? rawList
            .whereType<Map<String, dynamic>>()
            .map(AiSuggestedExercise.fromJson)
            .toList()
        : <AiSuggestedExercise>[];
    return AiGeneratedSession(
      exercises: exercises,
      coachingMessage: (data['coachingMessage'] ?? '').toString(),
      rationale: (data['rationale'] ?? '').toString(),
    );
  }

  Future<AiSuggestedExercise> swapExercise({
    required String currentExerciseCode,
    String? goal,
    String? sessionTitle,
    List<String> excludeCodes = const [],
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.aiSwapExercise,
      data: {
        'currentExerciseCode': currentExerciseCode,
        if (goal != null && goal.isNotEmpty) 'goal': goal,
        if (sessionTitle != null && sessionTitle.isNotEmpty)
          'sessionTitle': sessionTitle,
        'excludeExerciseCodes': excludeCodes,
      },
    );
    final data = _unwrap(response.data, 'Gợi ý bài thay thế thất bại');
    final raw = data['exercise'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid swap response data structure');
    }
    return AiSuggestedExercise.fromJson(raw);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? json, String fallbackMsg) {
    if (json == null || json['success'] != true) {
      throw Exception((json?['message'] ?? fallbackMsg).toString());
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return data;
  }
}
