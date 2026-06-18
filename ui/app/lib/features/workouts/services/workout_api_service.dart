import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/core/network/multipart_file_utils.dart';
import 'package:sync_app/core/network/dio_errors.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class WorkoutApiService {
  WorkoutApiService(this._dio);

  final Dio _dio;

  /// Active / recent personalized roadmaps for the authenticated user (AI-managed).
  Future<List<PersonalizedRoadmap>> getRoadmaps({int pageSize = 10}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.roadmaps,
      queryParameters: {'pageNumber': 1, 'pageSize': pageSize},
    );
    return _parsePagedList(response.data, PersonalizedRoadmap.fromJson);
  }

  /// All sessions belonging to a roadmap (non-paged list).
  Future<List<RoadmapSession>> getSessionsByRoadmap(String roadmapId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.sessionsByRoadmap(roadmapId),
    );
    return _parseList(response.data, RoadmapSession.fromJson);
  }

  /// Paged sessions (fallback / filter by roadmapId).
  Future<List<RoadmapSession>> getSessions({
    String? roadmapId,
    int pageSize = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.sessions,
      queryParameters: {
        'pageNumber': 1,
        'pageSize': pageSize,
        'roadmapId': roadmapId,
      },
    );
    return _parsePagedList(response.data, RoadmapSession.fromJson);
  }

  Future<RecoveryProfile?> getLatestRecoveryProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.recoveryProfiles,
        queryParameters: {'pageNumber': 1, 'pageSize': 1},
      );
      final list = _parsePagedList(response.data, RecoveryProfile.fromJson);
      return list.isEmpty ? null : list.first;
    } on DioException catch (e) {
      if (isOptionalApiDioError(e)) return null;
      rethrow;
    }
  }

  /// User-created custom workout templates (paginated).
  Future<List<UserCustomWorkout>> getCustomWorkouts({int pageSize = 50}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.customWorkouts,
      queryParameters: {'pageNumber': 1, 'pageSize': pageSize},
    );
    return _parsePagedList(response.data, UserCustomWorkout.fromJson);
  }

  Future<List<UserCustomWorkout>> getPublicWorkouts({
    String? query,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/public',
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (query != null && query.isNotEmpty) 'search': query,
        if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      },
    );
    return _parsePagedList(response.data, UserCustomWorkout.fromJson);
  }

  Future<UserCustomWorkout> cloneWorkout(String id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/$id/clone',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to clone workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return UserCustomWorkout.fromJson(raw);
  }

  Future<List<String>> uploadWorkoutCover(XFile file) async {
    final multipart = await multipartFileFromXFile(file);
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.roadmapWorkoutMediaUpload,
      data: FormData.fromMap({'files': [multipart]}),
      options: Options(contentType: 'multipart/form-data'),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Upload failed').toString());
    }
    final raw = json['data'];
    if (raw is List) {
      return raw
          .map((e) => MediaUrlResolver.resolve(e.toString()) ?? e.toString())
          .toList();
    }
    return <String>[];
  }

  Future<UserCustomWorkout> createCustomWorkout(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/custom',
      data: data,
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to create custom workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return UserCustomWorkout.fromJson(raw);
  }

  Future<UserCustomWorkout> updateCustomWorkout(String id, Map<String, dynamic> data) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/$id',
      data: data,
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to update custom workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return UserCustomWorkout.fromJson(raw);
  }

  Future<void> deleteCustomWorkout(String id) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/$id',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to delete custom workout').toString());
    }
  }

  Future<UserCustomWorkout> getCustomWorkoutById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/$id',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to load custom workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return UserCustomWorkout.fromJson(raw);
  }

  Future<MyWorkoutDetail> getCustomWorkoutDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.customWorkouts}/$id/detail',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to load custom workout detail').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return MyWorkoutDetail.fromJson(raw);
  }

  Future<RoadmapSession> getSessionById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.sessions}/$id',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to load session').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return RoadmapSession.fromJson(raw);
  }

  Future<Map<String, dynamic>> createRoadmapSession(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.sessions,
      data: data,
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to create session').toString());
    }
    return response.data!['data'] as Map<String, dynamic>;
  }

  Future<RoadmapSession> updateRoadmapSession(String sessionId, Map<String, dynamic> data) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '${ApiPaths.sessions}/$sessionId',
      data: data,
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to update session').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return RoadmapSession.fromJson(raw);
  }

  Future<Map<String, dynamic>> createScheduledWorkout(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.scheduledWorkouts,
      data: data,
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to create scheduled workout').toString());
    }
    return response.data!['data'] as Map<String, dynamic>;
  }

  Future<List<ExerciseCatalogItem>> searchExercises({
    String? query,
    String? category,
    int pageNumber = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.exercises,
      queryParameters: {
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null && category.isNotEmpty && category != 'All') 'category': category,
      },
    );
    return _parsePagedList(response.data, ExerciseCatalogItem.fromJson);
  }

  Future<ExerciseCatalogDetail?> getExerciseDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.exerciseDetail(id));
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      ExerciseCatalogDetail.fromJson,
    );
    if (!envelope.success) return null;
    return envelope.data;
  }

  Future<Map<String, String>> getExerciseThumbnailUrls(List<String> exerciseIds) async {
    if (exerciseIds.isEmpty) return {};
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.exerciseThumbnails,
      queryParameters: {'ids': exerciseIds},
    );
    final json = response.data;
    if (json == null || json['success'] != true) return {};
    final data = json['data'];
    if (data is! Map) return {};
    return data.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''))
        .map((key, value) => MapEntry(key, value))
        ..removeWhere((_, url) => url.isEmpty);
  }

  Future<WorkoutExecutionDetail> startWorkout(String sessionId, {int? energyLevelBefore}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.workoutExecutions}/start',
      data: {
        'sessionId': sessionId,
        if (energyLevelBefore != null) 'energyLevelBefore': energyLevelBefore,
      },
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to start workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return WorkoutExecutionDetail.fromJson(raw);
  }

  Future<WorkoutExecutionSummary> finishWorkout(
    String executionId, {
    int? perceivedDifficulty,
    int? energyLevelAfter,
    String? sessionFeedback,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.workoutExecutions}/$executionId/finish',
      data: {
        if (perceivedDifficulty != null) 'perceivedDifficulty': perceivedDifficulty,
        if (energyLevelAfter != null) 'energyLevelAfter': energyLevelAfter,
        if (sessionFeedback != null) 'sessionFeedback': sessionFeedback,
      },
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to finish workout').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return WorkoutExecutionSummary.fromJson(raw);
  }

  Future<void> cancelWorkout(String executionId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.workoutExecutions}/$executionId/cancel',
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to cancel workout').toString());
    }
  }

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
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.exerciseSetLogs,
      data: {
        'executionId': executionId,
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'targetReps': targetReps,
        'actualReps': actualReps,
        'weightKg': weightKg,
        'rir': rir,
        'restTakenSeconds': restTakenSeconds,
        'formScore': formScore,
        'completed': completed,
      },
    );
    if (response.data == null || response.data!['success'] != true) {
      throw Exception((response.data?['message'] ?? 'Failed to create set log').toString());
    }
    final raw = response.data!['data'];
    if (raw is! Map<String, dynamic>) {
      throw Exception('Invalid response data structure');
    }
    return ExerciseSetLog.fromJson(raw);
  }

  List<T> _parsePagedList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception((json?['message'] ?? 'Request failed').toString());
    }
    final raw = json['data'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  List<T> _parseList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception((json?['message'] ?? 'Request failed').toString());
    }
    final raw = json['data'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
