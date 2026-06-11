/// Mock current user for the Social feed (no auth).
class SocialFeedMockUser {
  const SocialFeedMockUser({
    required this.fullName,
    required this.avatarUrl,
  });

  final String fullName;
  final String avatarUrl;
}

const kSocialFeedMockUser = SocialFeedMockUser(
  fullName: 'Minh SYNC',
  avatarUrl: 'https://picsum.photos/seed/sync-me/200/200',
);

enum SocialFeedPostType {
  standard,
  achievementShare,
  streakShare,
  challengeCreation,
}

extension SocialFeedPostTypeX on SocialFeedPostType {
  String? get badgeLabel => switch (this) {
        SocialFeedPostType.standard => null,
        SocialFeedPostType.achievementShare => 'Chia sẻ thành tích',
        SocialFeedPostType.streakShare => 'Chuỗi ngày tập',
        SocialFeedPostType.challengeCreation => 'Thử thách mới',
      };

  String? get badgeEmoji => switch (this) {
        SocialFeedPostType.standard => null,
        SocialFeedPostType.achievementShare => '🏆',
        SocialFeedPostType.streakShare => '🔥',
        SocialFeedPostType.challengeCreation => '⚡',
      };
}

class SocialFeedDummyStory {
  const SocialFeedDummyStory({
    required this.id,
    required this.authorFullName,
    required this.authorAvatarUrl,
    this.mediaUrl,
    this.isSeen = false,
    this.isActive = true,
    this.isTextOnly = false,
  });

  final String id;
  final String authorFullName;
  final String authorAvatarUrl;
  final String? mediaUrl;
  final bool isSeen;
  final bool isActive;
  final bool isTextOnly;

  String get firstName {
    final parts = authorFullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : authorFullName;
  }
}

class SocialFeedDummyPost {
  const SocialFeedDummyPost({
    required this.id,
    required this.authorFullName,
    required this.authorAvatarUrl,
    required this.postType,
    required this.content,
    required this.mediaUrls,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.timeAgo,
    this.isPublic = true,
  });

  final String id;
  final String authorFullName;
  final String authorAvatarUrl;
  final SocialFeedPostType postType;
  final String content;
  final List<String> mediaUrls;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final String timeAgo;
  final bool isPublic;
}

const List<SocialFeedDummyStory> kSocialFeedMockStories = [
  SocialFeedDummyStory(
    id: 'story-1',
    authorFullName: 'Lan Nguyễn',
    authorAvatarUrl: 'https://picsum.photos/seed/story-lan/120/120',
    mediaUrl: 'https://picsum.photos/seed/story-bg-1/200/320',
    isSeen: false,
  ),
  SocialFeedDummyStory(
    id: 'story-2',
    authorFullName: 'Tuấn Phạm',
    authorAvatarUrl: 'https://picsum.photos/seed/story-tuan/120/120',
    mediaUrl: 'https://picsum.photos/seed/story-bg-2/200/320',
    isSeen: false,
  ),
  SocialFeedDummyStory(
    id: 'story-3',
    authorFullName: 'Hà Trần',
    authorAvatarUrl: 'https://picsum.photos/seed/story-ha/120/120',
    mediaUrl: 'https://picsum.photos/seed/story-bg-3/200/320',
    isSeen: true,
  ),
  SocialFeedDummyStory(
    id: 'story-4',
    authorFullName: 'Đức Lê',
    authorAvatarUrl: 'https://picsum.photos/seed/story-duc/120/120',
    mediaUrl: 'https://picsum.photos/seed/story-bg-4/200/320',
    isSeen: false,
  ),
  SocialFeedDummyStory(
    id: 'story-5',
    authorFullName: 'Mai Hoàng',
    authorAvatarUrl: 'https://picsum.photos/seed/story-mai/120/120',
    isTextOnly: true,
    isSeen: true,
  ),
  SocialFeedDummyStory(
    id: 'story-6',
    authorFullName: 'Khoa Vũ',
    authorAvatarUrl: 'https://picsum.photos/seed/story-khoa/120/120',
    mediaUrl: 'https://picsum.photos/seed/story-bg-6/200/320',
    isSeen: false,
  ),
];

const List<SocialFeedDummyPost> kSocialFeedMockPosts = [
  SocialFeedDummyPost(
    id: 'post-1',
    authorFullName: 'Trần Fitness',
    authorAvatarUrl: 'https://picsum.photos/seed/author-tran/120/120',
    postType: SocialFeedPostType.standard,
    content:
        'Buổi sáng nay tại công viên — năng lượng tuyệt vời! Đã hoàn thành 5km chạy bộ cùng nhóm SYNC. Ai rảnh cuối tuần join mình nhé 🏃‍♂️',
    mediaUrls: [
      'https://picsum.photos/seed/post1a/800/600',
      'https://picsum.photos/seed/post1b/800/600',
    ],
    likeCount: 89,
    commentCount: 12,
    shareCount: 4,
    timeAgo: '23 phút',
  ),
  SocialFeedDummyPost(
    id: 'post-2',
    authorFullName: 'Nguyễn Demo SYNC',
    authorAvatarUrl: 'https://picsum.photos/seed/author-demo/120/120',
    postType: SocialFeedPostType.achievementShare,
    content:
        'Vừa mở khóa huy hiệu "Marathon 21K" trên SYNC! Cảm ơn cộng đồng đã động viên suốt 8 tuần qua. Tiếp theo là mục tiêu 42K 💪',
    mediaUrls: [],
    likeCount: 214,
    commentCount: 38,
    shareCount: 15,
    timeAgo: '1 giờ',
  ),
  SocialFeedDummyPost(
    id: 'post-3',
    authorFullName: 'Lan Nguyễn',
    authorAvatarUrl: 'https://picsum.photos/seed/author-lan/120/120',
    postType: SocialFeedPostType.streakShare,
    content:
        'Chuỗi 30 ngày tập liên tiếp! Không bỏ lỡ một buổi nào — thói quen nhỏ mỗi ngày tạo nên sự khác biệt lớn.',
    mediaUrls: ['https://picsum.photos/seed/post3/800/500'],
    likeCount: 156,
    commentCount: 22,
    shareCount: 9,
    timeAgo: '2 giờ',
  ),
  SocialFeedDummyPost(
    id: 'post-4',
    authorFullName: 'SYNC Admin',
    authorAvatarUrl: 'https://picsum.photos/seed/author-admin/120/120',
    postType: SocialFeedPostType.challengeCreation,
    content:
        '🎯 Thử thách cộng đồng mới: «SYNC 10K Tuần Này». Cùng nhau đạt tổng quãng đường 10km từ thứ Hai đến Chủ Nhật. Tham gia ngay để nhận điểm thưởng và quà tặng độc quyền!',
    mediaUrls: [],
    likeCount: 342,
    commentCount: 56,
    shareCount: 78,
    timeAgo: 'Hôm qua',
  ),
  SocialFeedDummyPost(
    id: 'post-5',
    authorFullName: 'Hà Trần',
    authorAvatarUrl: 'https://picsum.photos/seed/author-ha/120/120',
    postType: SocialFeedPostType.standard,
    content:
        'Meal prep tuần này: cơm gạo lứt, ức gà, rau luộc và salad. Ăn sạch không nhàm chán nếu biết biến tấu 😉 Chia sẻ vài món yêu thích của mọi người nhé!',
    mediaUrls: [
      'https://picsum.photos/seed/post5a/800/600',
      'https://picsum.photos/seed/post5b/800/600',
      'https://picsum.photos/seed/post5c/800/600',
    ],
    likeCount: 127,
    commentCount: 19,
    shareCount: 6,
    timeAgo: 'Hôm qua',
  ),
];
