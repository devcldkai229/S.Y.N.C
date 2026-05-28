enum SocialMediaType { none, image, video }

class SocialAuthorSnapshot {
  const SocialAuthorSnapshot({required this.fullName, this.avatarUrl});

  final String fullName;
  final String? avatarUrl;

  factory SocialAuthorSnapshot.fromJson(Map<String, dynamic> json) {
    return SocialAuthorSnapshot(
      fullName: (json['fullName'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class SocialPostMetrics {
  const SocialPostMetrics({
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
  });

  final int likeCount;
  final int commentCount;
  final int shareCount;

  factory SocialPostMetrics.fromJson(Map<String, dynamic> json) {
    return SocialPostMetrics(
      likeCount: (json['likeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      shareCount: (json['shareCount'] ?? 0) as int,
    );
  }
}

class SocialPost {
  const SocialPost({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.authorId,
    required this.authorSnapshot,
    required this.postType,
    required this.content,
    this.mediaUrls = const [],
    this.referenceId,
    required this.metrics,
    required this.isPublic,
    required this.shareCode,
    this.isLikedByMe = false,
    this.isSharedByMe = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String authorId;
  final SocialAuthorSnapshot authorSnapshot;
  final String postType;
  final String content;
  final List<String> mediaUrls;
  final String? referenceId;
  final SocialPostMetrics metrics;
  final bool isPublic;
  final String shareCode;

  // Local-only flags (backend không trả về "liked by me"/"shared by me")
  final bool isLikedByMe;
  final bool isSharedByMe;

  SocialMediaType get mediaType {
    final first = mediaUrls.isNotEmpty ? mediaUrls.first : '';
    final lower = first.toLowerCase();
    if (lower.endsWith('.mp4') || lower.endsWith('.webm') || lower.endsWith('.mov')) {
      return SocialMediaType.video;
    }
    if (lower.endsWith('.png') || lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.gif') || lower.endsWith('.webp')) {
      return SocialMediaType.image;
    }
    return SocialMediaType.none;
  }

  String? get firstMediaUrl => mediaUrls.isNotEmpty ? mediaUrls.first : null;

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final authorSnapshotJson = json['authorSnapshot'] as Map<String, dynamic>? ?? const {};
    return SocialPost(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      authorId: json['authorId']?.toString() ?? '',
      authorSnapshot: SocialAuthorSnapshot.fromJson(authorSnapshotJson),
      postType: (json['postType'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      mediaUrls: (json['mediaUrls'] is List)
          ? (json['mediaUrls'] as List).map((e) => e.toString()).toList()
          : const [],
      referenceId: json['referenceId']?.toString(),
      metrics: SocialPostMetrics.fromJson((json['metrics'] ?? const {}) as Map<String, dynamic>),
      isPublic: json['isPublic'] == true,
      shareCode: (json['shareCode'] ?? '').toString(),
    );
  }

  SocialPost copyWith({
    SocialPostMetrics? metrics,
    bool? isLikedByMe,
    bool? isSharedByMe,
  }) {
    return SocialPost(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      authorId: authorId,
      authorSnapshot: authorSnapshot,
      postType: postType,
      content: content,
      mediaUrls: mediaUrls,
      referenceId: referenceId,
      metrics: metrics ?? this.metrics,
      isPublic: isPublic,
      shareCode: shareCode,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSharedByMe: isSharedByMe ?? this.isSharedByMe,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class SocialComment {
  SocialComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.authorSnapshot,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final SocialAuthorSnapshot? authorSnapshot;

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id']?.toString() ?? '',
      postId: json['postId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      authorSnapshot: json['authorSnapshot'] is Map<String, dynamic>
          ? SocialAuthorSnapshot.fromJson(json['authorSnapshot'] as Map<String, dynamic>)
          : null,
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class CursorFeedPage<T> {
  const CursorFeedPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

class CommentsPage {
  const CommentsPage({
    required this.items,
    required this.pageNumber,
    required this.totalPages,
  });

  final List<SocialComment> items;
  final int pageNumber;
  final int totalPages;

  bool get hasNextPage => pageNumber < totalPages;
}
