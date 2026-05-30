import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/social/models/social_models.dart';

class SocialRemoteDataSource {
  SocialRemoteDataSource(this._dio);

  final Dio _dio;

  Future<CursorFeedPage<SocialPost>> fetchFeed({String? cursor, int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.socialPosts}/feed',
      queryParameters: <String, dynamic>{
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
      },
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to fetch feed').toString());
    }

    final rawData = json['data'];
    final items = (rawData is List)
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(SocialPost.fromJson)
            .toList()
        : <SocialPost>[];

    final nextCursor = json['nextCursor']?.toString();
    return CursorFeedPage<SocialPost>(items: items, nextCursor: nextCursor);
  }

  Future<CursorFeedPage<SocialPost>> fetchUserWall({
    required String userId,
    String? cursor,
    int limit = 20,
    bool onlyMedia = false,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.socialPosts}/user/$userId',
      queryParameters: <String, dynamic>{
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
        'limit': limit,
        'onlyMedia': onlyMedia,
      },
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to fetch user wall').toString());
    }

    final rawData = json['data'];
    final items = (rawData is List)
        ? rawData
            .whereType<Map<String, dynamic>>()
            .map(SocialPost.fromJson)
            .toList()
        : <SocialPost>[];

    final nextCursor = json['nextCursor']?.toString();
    return CursorFeedPage<SocialPost>(items: items, nextCursor: nextCursor);
  }

  Future<void> deletePost(String postId) async {
    await _dio.delete<void>('${ApiPaths.socialPosts}/$postId');
  }

  Future<void> likePost(String postId) async {
    await _dio.post<void>('${ApiPaths.socialPosts}/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await _dio.delete<void>('${ApiPaths.socialPosts}/$postId/like');
  }

  Future<void> sharePost(String postId) async {
    await _dio.post<void>(
      '${ApiPaths.socialPosts}/$postId/interactions',
      data: <String, dynamic>{'interactionType': 'Share'},
    );
  }

  Future<CommentsPage> fetchComments(String postId, {int pageNumber = 1, int pageSize = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '${ApiPaths.socialPosts}/$postId/comments',
      queryParameters: <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load comments').toString());
    }

    final raw = json['data'];
    final items = (raw is List)
        ? raw.whereType<Map<String, dynamic>>().map(SocialComment.fromJson).toList()
        : <SocialComment>[];

    final pagination = (json['pagination'] as Map<String, dynamic>? ?? const {});
    final totalPages = (pagination['totalPages'] ?? 0) as int;
    final resolvedPageNumber = (pagination['pageNumber'] ?? pageNumber) as int;

    return CommentsPage(items: items, pageNumber: resolvedPageNumber, totalPages: totalPages);
  }

  Future<SocialComment> createComment({
    required String postId,
    required String content,
    required String authorFullName,
    String? authorAvatarUrl,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.socialPosts}/$postId/comments',
      data: <String, dynamic>{
        'content': content,
        'authorSnapshot': <String, dynamic>{
          'fullName': authorFullName,
          'avatarUrl': authorAvatarUrl,
        }
      },
    );

    final data = response.data?['data'];
    if (data is Map<String, dynamic>) {
      return SocialComment.fromJson(data);
    }
    throw Exception('Create comment failed (missing data).');
  }

  Future<List<String>> uploadMediaFiles(List<String> filePaths) async {
    final files = <MultipartFile>[];
    for (final p in filePaths) {
      // support Windows paths
      if (p.trim().isEmpty) continue;
      files.add(await MultipartFile.fromFile(p, filename: p.split('\\').last));
    }

    final formData = FormData.fromMap(<String, dynamic>{
      'files': files,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '${ApiPaths.socialPosts}/media/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Upload failed').toString());
    }

    final raw = json['data'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  Future<SocialPost> createPost({
    required String content,
    required List<String> mediaUrls,
    required bool isPublic,
    required String authorFullName,
    String? authorAvatarUrl,
    String postType = 'Standard',
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.socialPosts,
      data: <String, dynamic>{
        'postType': postType,
        'content': content,
        'mediaUrls': mediaUrls,
        'isPublic': isPublic,
        'authorSnapshot': <String, dynamic>{
          'fullName': authorFullName,
          'avatarUrl': authorAvatarUrl,
        },
      },
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Create post failed').toString());
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return SocialPost.fromJson(data);
    }
    throw Exception('Create post failed (missing data).');
  }
}
