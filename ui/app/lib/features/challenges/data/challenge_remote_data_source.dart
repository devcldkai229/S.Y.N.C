import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/models/challenge_participation_models.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';

class ChallengeRemoteDataSource {
  ChallengeRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CommunityChallenge>> fetchChallenges({
    int page = 1,
    int pageSize = 40,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.challenges,
      queryParameters: {
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    return _parseChallengeList(response.data);
  }

  Future<List<CommunityChallenge>> fetchNearbyChallenges({
    required double userLat,
    required double userLng,
    double radiusKm = 50,
    int page = 1,
    int pageSize = 40,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.challengesNearby,
      queryParameters: {
        'userLat': userLat,
        'userLng': userLng,
        'radiusKm': radiusKm,
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    return _parseChallengeList(response.data);
  }

  Future<CommunityChallenge> fetchChallengeById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.challengeById(id));
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load challenge').toString());
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid challenge response');
    }
    return CommunityChallenge.fromJson(data);
  }

  Future<ChallengeRoute> fetchRoute({
    required String challengeId,
    required double userLat,
    required double userLng,
    String? travelMode,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.challengeRoute(challengeId),
      queryParameters: {
        'userLat': userLat,
        'userLng': userLng,
        if (travelMode != null) 'travelMode': travelMode,
      },
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load route').toString());
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid route response');
    }
    return ChallengeRoute.fromJson(data);
  }

  Future<ChallengeParticipationStatus> fetchParticipationStatus(String challengeId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.challengeParticipationStatus(challengeId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load participation status').toString());
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return ChallengeParticipationStatus.fromJson(data);
    }
    return const ChallengeParticipationStatus(hasJoined: false);
  }

  Future<void> joinChallenge(String challengeId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.challengeJoin(challengeId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Join challenge failed').toString());
    }
  }

  Future<void> leaveChallenge(String challengeId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.challengeLeave(challengeId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Leave challenge failed').toString());
    }
  }

  List<CommunityChallenge> _parseChallengeList(Map<String, dynamic>? json) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! List) return [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(CommunityChallenge.fromJson)
        .toList();
  }
}
