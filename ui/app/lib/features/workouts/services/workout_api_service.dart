import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class WorkoutApiService {
  WorkoutApiService(this._dio);

  final Dio _dio;

  Future<List<PersonalizedRoadmap>> getRoadmaps({int pageSize = 10}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.roadmaps,
      queryParameters: {'pageNumber': 1, 'pageSize': pageSize},
    );
    return _parsePagedList(response.data, PersonalizedRoadmap.fromJson);
  }

  Future<List<RoadmapSession>> getSessions({
    String? roadmapId,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.sessions,
      queryParameters: {
        'pageNumber': 1,
        'pageSize': pageSize,
        if (roadmapId != null) 'roadmapId': roadmapId,
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

  Future<ExerciseCatalogItem?> getExerciseDetail(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.exerciseDetail(id));
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      ExerciseCatalogItem.fromJson,
    );
    if (!envelope.success) return null;
    return envelope.data;
  }

  List<T> _parsePagedList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null) return [];
    final raw = json['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList();
  }
}
