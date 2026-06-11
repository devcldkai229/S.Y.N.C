import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
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

  Future<List<SocialStoryFeedGroup>> fetchStoriesFeed() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.socialStoriesFeed);
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to fetch stories').toString());
    }
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SocialStoryFeedGroup.fromJson)
        .toList();
  }

  Future<List<SocialStory>> fetchMyStories() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.socialStoriesMe);
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to fetch my stories').toString());
    }
    final raw = json['data'];
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map(SocialStory.fromJson).toList();
  }

  Future<void> viewStory(String storyId) async {
    await _dio.post<void>('${ApiPaths.socialStories}/$storyId/view');
  }

  Future<void> likeStory(String storyId) async {
    await _dio.post<void>('${ApiPaths.socialStories}/$storyId/like');
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
    String? authorFullName,
    String? authorAvatarUrl,
  }) async {
    final path = '${ApiPaths.socialPosts}/$postId/comments';
    final payload = <String, dynamic>{
      'content': content,
      if (authorFullName != null && authorFullName.isNotEmpty)
        'authorSnapshot': <String, dynamic>{
          'fullName': authorFullName,
          if (authorAvatarUrl != null) 'avatarUrl': authorAvatarUrl,
        },
    };

    if (kDebugMode) {
      debugPrint('[Social] POST $path');
      debugPrint('[Social] payload: $payload');
      debugPrint('[Social] Authorization: ${_dio.options.headers['Authorization'] ?? '(from interceptor)'}');
    }

    final response = await _dio.post<Map<String, dynamic>>(path, data: payload);
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Create comment failed').toString());
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return SocialComment.fromJson(data);
    }
    throw Exception('Create comment failed (missing data).');
  }

  Future<SocialComment> createReply({
    required String commentId,
    required String content,
    required String parentCommentId,
    String? authorFullName,
    String? authorAvatarUrl,
  }) async {
    final path = ApiPaths.socialCommentReplies(commentId);
    final payload = <String, dynamic>{
      'content': content,
      'parentCommentId': parentCommentId,
      if (authorFullName != null && authorFullName.isNotEmpty)
        'authorSnapshot': <String, dynamic>{
          'fullName': authorFullName,
          if (authorAvatarUrl != null) 'avatarUrl': authorAvatarUrl,
        },
    };

    if (kDebugMode) {
      debugPrint('[Social] POST $path');
      debugPrint('[Social] payload: $payload');
      debugPrint('[Social] Authorization: ${_dio.options.headers['Authorization'] ?? '(from interceptor)'}');
    }

    final response = await _dio.post<Map<String, dynamic>>(path, data: payload);
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Create reply failed').toString());
    }

    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return SocialComment.fromJson(data);
    }
    throw Exception('Create reply failed (missing data).');
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

  Future<SocialStory> createStory({
    required String filePath,
    String? caption,
    required String authorFullName,
    String? authorAvatarUrl,
  }) async {
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final multipart = await MultipartFile.fromFile(filePath, filename: fileName);

    final formData = FormData.fromMap(<String, dynamic>{
      'file': multipart,
      if (caption != null && caption.isNotEmpty) 'caption': caption,
      'authorFullName': authorFullName,
      if (authorAvatarUrl != null) 'authorAvatarUrl': authorAvatarUrl,
    });

    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.socialStories,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Create story failed').toString());
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return SocialStory.fromJson(data);
    }
    throw Exception('Create story failed (missing data).');
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

  Future<FollowCounts> fetchFollowCounts(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialUserFollowCounts(userId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load follow counts').toString());
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return FollowCounts.fromJson(data);
    }
    return FollowCounts.empty;
  }

  Future<FollowStatus> fetchFollowStatus(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialUserFollowStatus(userId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load follow status').toString());
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return FollowStatus.fromJson(data);
    }
    return FollowStatus.none;
  }

  Future<void> followUser(String userId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.socialUserFollow(userId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Follow failed').toString());
    }
  }

  Future<void> unfollowUser(String userId) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      ApiPaths.socialUserFollow(userId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Unfollow failed').toString());
    }
  }
}
