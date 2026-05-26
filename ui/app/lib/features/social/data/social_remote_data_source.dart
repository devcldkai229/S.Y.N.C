import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/social/data/social_mock_data.dart';
import 'package:sync_app/features/social/models/social_models.dart';

/// Gọi API khi có Social service; hiện fallback mock nếu API chưa có.
class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<SocialPost>> fetchFeed({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.socialPosts,
        queryParameters: {'pageNumber': page, 'pageSize': pageSize},
      );
      final raw = response.data?['data'];
      if (raw is List && raw.isNotEmpty) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(SocialPost.fromJson)
            .toList();
      }
    } catch (_) {
      // Social API chưa deploy — dùng mock
    }
    return SocialMockData.initialPosts();
  }

  Future<void> toggleLike(String postId, bool like) async {
    try {
      await _dio.post<void>('${ApiPaths.socialPosts}/$postId/like', data: {'like': like});
    } catch (_) {}
  }

  Future<void> toggleDislike(String postId, bool dislike) async {
    try {
      await _dio.post<void>(
        '${ApiPaths.socialPosts}/$postId/dislike',
        data: {'dislike': dislike},
      );
    } catch (_) {}
  }

  Future<SocialComment> addComment(String postId, String content) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '${ApiPaths.socialPosts}/$postId/comments',
        data: {'content': content},
      );
      final data = response.data?['data'];
      if (data is Map<String, dynamic>) {
        return SocialComment.fromJson(data);
      }
    } catch (_) {}
    return SocialComment(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'You',
      content: content,
      createdAt: DateTime.now(),
    );
  }
}
