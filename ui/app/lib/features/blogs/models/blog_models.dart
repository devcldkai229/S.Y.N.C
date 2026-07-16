import 'package:sync_app/features/social/models/social_models.dart';

class BlogPost {
  const BlogPost({
    required this.id,
    required this.authorId,
    required this.authorSnapshot,
    required this.title,
    required this.slug,
    required this.coverImageUrl,
    required this.content,
    required this.tags,
    required this.status,
    this.publishedAt,
    this.createdAt,
    this.likeCount = 0,
    this.shareCount = 0,
    this.commentCount = 0,
    this.isLikedByMe = false,
    this.mediaUrls = const [],
  });

  final String id;
  final String authorId;
  final SocialAuthorSnapshot authorSnapshot;
  final String title;
  final String slug;
  final String coverImageUrl;
  final String content;
  final List<String> tags;
  final String status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final int likeCount;
  final int shareCount;
  final int commentCount;
  final bool isLikedByMe;
  final List<String> mediaUrls;

  factory BlogPost.fromJson(Map<String, dynamic> json) {
    final authorJson = (json['authorSnapshot'] as Map<String, dynamic>?) ?? const {};
    final mediaRaw = json['mediaUrls'];
    final tagsRaw = json['tags'];

    return BlogPost(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorSnapshot: SocialAuthorSnapshot.fromJson(authorJson),
      title: (json['title'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      coverImageUrl: (json['coverImageUrl'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      tags: tagsRaw is List
          ? tagsRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
      status: (json['status'] ?? '').toString(),
      publishedAt: _parseDate(json['publishedAt']),
      createdAt: _parseDate(json['createdAt']),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['isLikedByMe'] == true,
      mediaUrls: mediaRaw is List
          ? mediaRaw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
          : const [],
    );
  }

  BlogPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLikedByMe,
  }) {
    return BlogPost(
      id: id,
      authorId: authorId,
      authorSnapshot: authorSnapshot,
      title: title,
      slug: slug,
      coverImageUrl: coverImageUrl,
      content: content,
      tags: tags,
      status: status,
      publishedAt: publishedAt,
      createdAt: createdAt,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      mediaUrls: mediaUrls,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}

class BlogComment {
  const BlogComment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorSnapshot,
  });

  final String id;
  final String blogId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final SocialAuthorSnapshot? authorSnapshot;

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    return BlogComment(
      id: json['id']?.toString() ?? '',
      blogId: json['blogId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
          DateTime.now(),
      authorSnapshot: json['authorSnapshot'] is Map<String, dynamic>
          ? SocialAuthorSnapshot.fromJson(json['authorSnapshot'] as Map<String, dynamic>)
          : null,
    );
  }
}

class BlogPage {
  const BlogPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
    required this.totalRecords,
  });

  final List<BlogPost> items;
  final int pageNumber;
  final int totalPages;
  final int totalRecords;

  bool get hasMore => pageNumber < totalPages;
}

class BlogCommentsPage {
  const BlogCommentsPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  final List<BlogComment> items;
  final int pageNumber;
  final int totalPages;

  bool get hasMore => pageNumber < totalPages;
}
