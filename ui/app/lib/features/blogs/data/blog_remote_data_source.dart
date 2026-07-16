import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';

class BlogRemoteDataSource {
  BlogRemoteDataSource(this._dio);

  final Dio _dio;

  Future<BlogPage> fetchPublished({int pageNumber = 1, int pageSize = 20, String? tag}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialBlogs,
      queryParameters: <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
        if (tag != null && tag.isNotEmpty) 'tag': tag,
      },
    );
    return _parseBlogPage(response.data, fallbackPage: pageNumber);
  }

  Future<BlogPage> search({
    required String q,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialBlogsSearch,
      queryParameters: <String, dynamic>{
        'q': q,
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );
    return _parseBlogPage(response.data, fallbackPage: pageNumber);
  }

  Future<BlogPost> fetchById(String blogId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialBlogById(blogId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load blog').toString());
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid blog payload');
    }
    return BlogPost.fromJson(data);
  }

  Future<({int likeCount, int shareCount})> like(String blogId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.socialBlogLike(blogId),
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Like failed').toString());
    }
    final data = (json['data'] as Map<String, dynamic>?) ?? const {};
    return (
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      shareCount: (data['shareCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<BlogCommentsPage> fetchComments(
    String blogId, {
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.socialBlogComments(blogId),
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
        ? raw.whereType<Map<String, dynamic>>().map(BlogComment.fromJson).toList()
        : <BlogComment>[];

    final pagination = (json['pagination'] as Map<String, dynamic>?) ?? const {};
    final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
    final resolvedPage = (pagination['pageNumber'] as num?)?.toInt() ?? pageNumber;

    return BlogCommentsPage(items: items, pageNumber: resolvedPage, totalPages: totalPages);
  }

  Future<BlogComment> createComment({
    required String blogId,
    required String content,
    String? authorFullName,
    String? authorAvatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'content': content,
      if (authorFullName != null && authorFullName.isNotEmpty)
        'authorSnapshot': <String, dynamic>{
          'fullName': authorFullName,
          if (authorAvatarUrl != null) 'avatarUrl': authorAvatarUrl,
        },
    };

    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.socialBlogComments(blogId),
      data: payload,
    );
    final json = response.data ?? const {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Create comment failed').toString());
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid comment payload');
    }
    return BlogComment.fromJson(data);
  }

  BlogPage _parseBlogPage(Map<String, dynamic>? json, {required int fallbackPage}) {
    final body = json ?? const {};
    if (body['success'] != true) {
      throw Exception((body['message'] ?? 'Failed to load blogs').toString());
    }

    final raw = body['data'];
    final items = (raw is List)
        ? raw.whereType<Map<String, dynamic>>().map(BlogPost.fromJson).toList()
        : <BlogPost>[];

    final pagination = (body['pagination'] as Map<String, dynamic>?) ?? const {};
    final pageNumber = (pagination['pageNumber'] as num?)?.toInt() ?? fallbackPage;
    final totalPages = (pagination['totalPages'] as num?)?.toInt() ?? 1;
    final totalRecords = (pagination['totalRecords'] as num?)?.toInt() ?? items.length;

    return BlogPage(
      items: items,
      pageNumber: pageNumber,
      totalPages: totalPages,
      totalRecords: totalRecords,
    );
  }
}
