import 'package:sync_app/features/social/models/social_models.dart';

/// Demo feed — thay bằng API khi có Social service.
abstract final class SocialMockData {
  static List<SocialPost> initialPosts() {
    final now = DateTime.now();
    const shareCode = 'ABCD1234';
    return [
      SocialPost(
        id: 'post-1',
        authorId: 'u-1',
        authorSnapshot: SocialAuthorSnapshot(fullName: 'Alex Mercer'),
        postType: 'Standard',
        content:
            'Phase 2 hypertrophy check-in — hit a new PR on bench today. Who else is pushing upper body this week?',
        mediaUrls: const [
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
        ],
        metrics: const SocialPostMetrics(likeCount: 128, commentCount: 24, shareCount: 3),
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: null,
        referenceId: null,
        isPublic: true,
        shareCode: shareCode,
      ),
      SocialPost(
        id: 'post-2',
        authorId: 'u-2',
        authorSnapshot: SocialAuthorSnapshot(fullName: 'SYNC Coach AI'),
        postType: 'Standard',
        content: 'Form tip: keep your rib cage stacked on Romanian deadlifts. Watch the 30s breakdown.',
        mediaUrls: const [
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        ],
        metrics: const SocialPostMetrics(likeCount: 342, commentCount: 56, shareCount: 8),
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: null,
        referenceId: null,
        isPublic: true,
        shareCode: shareCode,
      ),
      SocialPost(
        id: 'post-3',
        authorId: 'u-3',
        authorSnapshot: SocialAuthorSnapshot(fullName: 'Mia Tran'),
        postType: 'Standard',
        content: 'Meal prep Sunday — high protein bowls for the cut phase.',
        mediaUrls: const [
          'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
        ],
        metrics: const SocialPostMetrics(likeCount: 89, commentCount: 12, shareCount: 1),
        createdAt: now.subtract(const Duration(hours: 8)),
        updatedAt: null,
        referenceId: null,
        isPublic: true,
        shareCode: shareCode,
      ),
      SocialPost(
        id: 'post-4',
        authorId: 'u-4',
        authorSnapshot: SocialAuthorSnapshot(fullName: 'Jordan Lee'),
        postType: 'Standard',
        content: 'Active recovery flow — 20 min mobility after leg day.',
        mediaUrls: const [
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        ],
        metrics: const SocialPostMetrics(likeCount: 201, commentCount: 31, shareCount: 4),
        isLikedByMe: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: null,
        referenceId: null,
        isPublic: true,
        shareCode: shareCode,
      ),
      SocialPost(
        id: 'post-5',
        authorId: 'u-5',
        authorSnapshot: const SocialAuthorSnapshot(fullName: 'Sync Community'),
        postType: 'Standard',
        content:
            'Weekly challenge: complete 4 sessions and earn bonus Sync Coins. Tag your crew below.',
        mediaUrls: const [],
        metrics: const SocialPostMetrics(likeCount: 512, commentCount: 98, shareCount: 12),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: null,
        referenceId: null,
        isPublic: true,
        shareCode: shareCode,
      ),
    ];
  }
}
