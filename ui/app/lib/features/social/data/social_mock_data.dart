import 'package:sync_app/features/social/models/social_models.dart';

/// Demo feed — thay bằng API khi có Social service.
abstract final class SocialMockData {
  static List<SocialPost> initialPosts() {
    final now = DateTime.now();
    return [
      SocialPost(
        id: 'post-1',
        authorName: 'Alex Mercer',
        content:
            'Phase 2 hypertrophy check-in — hit a new PR on bench today. Who else is pushing upper body this week?',
        mediaType: SocialMediaType.image,
        imageUrl:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
        likeCount: 128,
        dislikeCount: 3,
        commentCount: 24,
        createdAt: now.subtract(const Duration(hours: 2)),
        comments: [
          SocialComment(
            id: 'c1',
            authorName: 'Mia Tran',
            content: 'Huge progress! What\'s your weekly volume looking like?',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
          SocialComment(
            id: 'c2',
            authorName: 'Jordan Lee',
            content: 'Respect the consistency.',
            createdAt: now.subtract(const Duration(minutes: 45)),
          ),
        ],
      ),
      SocialPost(
        id: 'post-2',
        authorName: 'SYNC Coach AI',
        content: 'Form tip: keep your rib cage stacked on Romanian deadlifts. Watch the 30s breakdown.',
        mediaType: SocialMediaType.video,
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        videoThumbnailUrl:
            'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50e?w=800&q=80',
        likeCount: 342,
        dislikeCount: 8,
        commentCount: 56,
        createdAt: now.subtract(const Duration(hours: 5)),
        comments: [
          SocialComment(
            id: 'c3',
            authorName: 'Kai Nguyen',
            content: 'This fixed my lower back rounding issue.',
            createdAt: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      SocialPost(
        id: 'post-3',
        authorName: 'Mia Tran',
        content: 'Meal prep Sunday — high protein bowls for the cut phase.',
        mediaType: SocialMediaType.image,
        imageUrl:
            'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
        likeCount: 89,
        dislikeCount: 1,
        commentCount: 12,
        createdAt: now.subtract(const Duration(hours: 8)),
        comments: [],
      ),
      SocialPost(
        id: 'post-4',
        authorName: 'Jordan Lee',
        content: 'Active recovery flow — 20 min mobility after leg day.',
        mediaType: SocialMediaType.video,
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        videoThumbnailUrl:
            'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&q=80',
        likeCount: 201,
        dislikeCount: 4,
        commentCount: 31,
        isLikedByMe: true,
        createdAt: now.subtract(const Duration(days: 1)),
        comments: [
          SocialComment(
            id: 'c4',
            authorName: 'Alex Mercer',
            content: 'Saving this for tomorrow morning.',
            createdAt: now.subtract(const Duration(hours: 20)),
          ),
        ],
      ),
      SocialPost(
        id: 'post-5',
        authorName: 'Sync Community',
        content:
            'Weekly challenge: complete 4 sessions and earn bonus Sync Coins. Tag your crew below.',
        mediaType: SocialMediaType.none,
        likeCount: 512,
        dislikeCount: 12,
        commentCount: 98,
        createdAt: now.subtract(const Duration(days: 2)),
        comments: [],
      ),
    ];
  }
}
