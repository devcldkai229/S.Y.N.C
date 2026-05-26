enum SocialMediaType { none, image, video }

class SocialComment {
  SocialComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    this.authorAvatarUrl,
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final DateTime createdAt;

  factory SocialComment.fromJson(Map<String, dynamic> json) {
    return SocialComment(
      id: json['id']?.toString() ?? '',
      authorName: (json['authorName'] ?? '').toString(),
      authorAvatarUrl: json['authorAvatarUrl']?.toString(),
      content: (json['content'] ?? '').toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class SocialPost {
  SocialPost({
    required this.id,
    required this.authorName,
    required this.content,
    required this.mediaType,
    required this.likeCount,
    required this.dislikeCount,
    required this.commentCount,
    required this.createdAt,
    this.authorAvatarUrl,
    this.imageUrl,
    this.videoUrl,
    this.videoThumbnailUrl,
    this.isLikedByMe = false,
    this.isDislikedByMe = false,
    this.comments = const [],
  });

  final String id;
  final String authorName;
  final String? authorAvatarUrl;
  final String content;
  final SocialMediaType mediaType;
  final String? imageUrl;
  final String? videoUrl;
  final String? videoThumbnailUrl;
  final int likeCount;
  final int dislikeCount;
  final int commentCount;
  final bool isLikedByMe;
  final bool isDislikedByMe;
  final List<SocialComment> comments;
  final DateTime createdAt;

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final media = (json['mediaType'] ?? '').toString().toLowerCase();
    SocialMediaType type = SocialMediaType.none;
    if (media.contains('image')) type = SocialMediaType.image;
    if (media.contains('video')) type = SocialMediaType.video;

    final rawComments = json['comments'];
    return SocialPost(
      id: json['id']?.toString() ?? '',
      authorName: (json['authorName'] ?? '').toString(),
      authorAvatarUrl: json['authorAvatarUrl']?.toString(),
      content: (json['content'] ?? '').toString(),
      mediaType: type,
      imageUrl: json['imageUrl']?.toString(),
      videoUrl: json['videoUrl']?.toString(),
      videoThumbnailUrl: json['videoThumbnailUrl']?.toString(),
      likeCount: (json['likeCount'] ?? 0) as int,
      dislikeCount: (json['dislikeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      isLikedByMe: json['isLikedByMe'] == true,
      isDislikedByMe: json['isDislikedByMe'] == true,
      comments: rawComments is List
          ? rawComments
              .whereType<Map<String, dynamic>>()
              .map(SocialComment.fromJson)
              .toList()
          : [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  SocialPost copyWith({
    int? likeCount,
    int? dislikeCount,
    int? commentCount,
    bool? isLikedByMe,
    bool? isDislikedByMe,
    List<SocialComment>? comments,
  }) {
    return SocialPost(
      id: id,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      content: content,
      mediaType: mediaType,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      videoThumbnailUrl: videoThumbnailUrl,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      commentCount: commentCount ?? this.commentCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isDislikedByMe: isDislikedByMe ?? this.isDislikedByMe,
      comments: comments ?? this.comments,
      createdAt: createdAt,
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
