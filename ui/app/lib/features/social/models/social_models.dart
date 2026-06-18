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
      isLikedByMe: json['isLikedByMe'] == true,
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

  String get timeAgoVi => formatRelativeTimeVi(createdAt);

  /// English fallback used by legacy [SocialPostCard].
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String? get badgeLabel => switch (postType) {
        'AchievementShare' => 'Chia sẻ thành tích',
        'StreakShare' => 'Chuỗi ngày tập',
        'ChallengeCreation' => 'Thử thách mới',
        _ => null,
      };

  String? get badgeEmoji => switch (postType) {
        'AchievementShare' => '🏆',
        'StreakShare' => '🔥',
        'ChallengeCreation' => '⚡',
        _ => null,
      };
}

String formatRelativeTimeVi(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút';
  if (diff.inHours < 24) return '${diff.inHours} giờ';
  if (diff.inDays == 1) return 'Hôm qua';
  return '${diff.inDays} ngày';
}

class SocialStory {
  const SocialStory({
    required this.id,
    required this.authorId,
    required this.authorSnapshot,
    required this.mediaUrl,
    required this.mediaType,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.isLikedByMe = false,
  });

  final String id;
  final String authorId;
  final SocialAuthorSnapshot authorSnapshot;
  final String mediaUrl;
  final String mediaType;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isLikedByMe;

  bool get isTextOnly => mediaType == 'TextOnly' || mediaUrl.isEmpty;

  factory SocialStory.fromJson(Map<String, dynamic> json) {
    final authorSnapshotJson = json['authorSnapshot'] as Map<String, dynamic>? ?? const {};
    return SocialStory(
      id: json['id']?.toString() ?? '',
      authorId: json['authorId']?.toString() ?? '',
      authorSnapshot: SocialAuthorSnapshot.fromJson(authorSnapshotJson),
      mediaUrl: (json['mediaUrl'] ?? '').toString(),
      mediaType: (json['mediaType'] ?? '').toString(),
      caption: json['caption']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? '') ?? DateTime.now(),
      isLikedByMe: json['isLikedByMe'] == true,
    );
  }

  SocialStory copyWith({bool? isLikedByMe}) {
    return SocialStory(
      id: id,
      authorId: authorId,
      authorSnapshot: authorSnapshot,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption,
      createdAt: createdAt,
      expiresAt: expiresAt,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}

class SocialStoryFeedGroup {
  const SocialStoryFeedGroup({
    required this.authorId,
    required this.authorSnapshot,
    required this.stories,
  });

  final String authorId;
  final SocialAuthorSnapshot authorSnapshot;
  final List<SocialStory> stories;

  SocialStory? get previewStory =>
      stories.isNotEmpty ? stories.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b) : null;

  String get firstName {
    final parts = authorSnapshot.fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : authorSnapshot.fullName;
  }

  factory SocialStoryFeedGroup.fromJson(Map<String, dynamic> json) {
    final authorSnapshotJson = json['authorSnapshot'] as Map<String, dynamic>? ?? const {};
    final rawStories = json['stories'];
    return SocialStoryFeedGroup(
      authorId: json['authorId']?.toString() ?? '',
      authorSnapshot: SocialAuthorSnapshot.fromJson(authorSnapshotJson),
      stories: rawStories is List
          ? rawStories
              .whereType<Map<String, dynamic>>()
              .map(SocialStory.fromJson)
              .toList()
          : const [],
    );
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
    this.parentCommentId,
  });

  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final SocialAuthorSnapshot? authorSnapshot;
  final String? parentCommentId;

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
      parentCommentId: json['parentCommentId']?.toString(),
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

class PagedSearchPage<T> {
  const PagedSearchPage({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
  });

  final List<T> items;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;

  bool get hasNextPage {
    if (pageSize <= 0) return false;
    return pageNumber * pageSize < totalRecords;
  }
}

class UserSearchResult {
  const UserSearchResult({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.outgoingStatus,
    this.canFollow = true,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? outgoingStatus;
  final bool canFollow;

  bool get isFollowing => outgoingStatus == 'Accepted';
  bool get isPending => outgoingStatus == 'Pending';

  UserSearchResult copyWith({
    String? outgoingStatus,
    bool? canFollow,
  }) {
    return UserSearchResult(
      id: id,
      fullName: fullName,
      avatarUrl: avatarUrl,
      outgoingStatus: outgoingStatus ?? this.outgoingStatus,
      canFollow: canFollow ?? this.canFollow,
    );
  }

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      outgoingStatus: json['outgoingStatus']?.toString(),
      canFollow: json['canFollow'] != false,
    );
  }
}
