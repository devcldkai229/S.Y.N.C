import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
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
        'roadmapId': ?roadmapId,
      },
    );
    return _parsePagedList(response.data, RoadmapSession.fromJson);
  }

  Future<RecoveryProfile?> getLatestRecoveryProfile() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.recoveryProfiles,
      queryParameters: {'pageNumber': 1, 'pageSize': 1},
    );
    final list = _parsePagedList(response.data, RecoveryProfile.fromJson);
    return list.isEmpty ? null : list.first;
  }

  /// User-created custom workout templates (paginated).
  Future<List<UserCustomWorkout>> getCustomWorkouts({int pageSize = 50}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.customWorkouts,
      queryParameters: {'pageNumber': 1, 'pageSize': pageSize},
    );
    return _parsePagedList(response.data, UserCustomWorkout.fromJson);
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
