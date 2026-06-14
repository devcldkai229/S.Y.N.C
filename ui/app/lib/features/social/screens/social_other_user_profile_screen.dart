import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/context_navigation.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/achievements/models/achievement_display_data.dart';
import 'package:sync_app/features/achievements/widgets/in_progress_achievement_card.dart';
import 'package:sync_app/features/achievements/widgets/unlocked_achievement_card.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/widgets/social_comments_sheet.dart';
import 'package:sync_app/features/social/widgets/social_feed_post_card.dart';
import 'package:sync_app/features/social/widgets/social_post_actions.dart';
import 'package:sync_app/features/social/widgets/social_post_share_sheet.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

const _coverHeight = 200.0;
const _avatarRadius = 45.0;
/// Premium Facebook/Instagram-style profile for another user.
class SocialOtherUserProfileScreen extends StatelessWidget {
  const SocialOtherUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: _OtherUserProfileBody(userId: userId),
    );
  }
}

class _OtherUserProfileBody extends StatefulWidget {
  const _OtherUserProfileBody({required this.userId});

  final String userId;

  @override
  State<_OtherUserProfileBody> createState() => _OtherUserProfileBodyState();
}

class _OtherUserProfileBodyState extends State<_OtherUserProfileBody> {
  final SocialRepository _socialRepo = getIt<SocialRepository>();
  final ProfileApiService _profileApi = getIt<ProfileApiService>();

  static const _pageLimit = 20;

  PublicProfile? _profile;
  bool _profileLoading = true;

  FollowCounts _followCounts = FollowCounts.empty;
  FollowStatus _followStatus = FollowStatus.none;
  bool _followLoading = false;
  bool _followActionLoading = false;

  final List<SocialPost> _posts = [];
  bool _postsLoading = false;
  bool _postsLoadingMore = false;
  String? _postsCursor;
  bool _postsHasMore = false;

  final Set<String> _likedPostIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadProfile(),
      _loadFollowData(),
      _loadPosts(refresh: true),
    ]);
  }

  Future<void> _loadProfile() async {
    if (widget.userId.isEmpty) return;
    setState(() => _profileLoading = true);
    try {
      final profile = await _profileApi.getPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _profileLoading = false);
    }
  }

  Future<void> _loadFollowData() async {
    if (widget.userId.isEmpty) return;
    setState(() => _followLoading = true);
    try {
      final results = await Future.wait([
        _socialRepo.loadFollowCounts(widget.userId),
        _socialRepo.loadFollowStatus(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _followCounts = results[0] as FollowCounts;
        _followStatus = results[1] as FollowStatus;
        _followLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _followLoading = false);
    }
  }

  Future<void> _loadPosts({required bool refresh}) async {
    if (!mounted) return;
    setState(() {
      _postsLoading = refresh;
      if (refresh) {
        _posts.clear();
        _postsCursor = null;
        _postsHasMore = false;
      }
    });

    try {
      final page = await _socialRepo.loadUserWall(
        userId: widget.userId,
        cursor: refresh ? null : _postsCursor,
        limit: _pageLimit,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(page.items);
        } else {
          _posts.addAll(page.items);
        }
        for (final p in page.items) {
          if (p.isLikedByMe) _likedPostIds.add(p.id);
        }
        _postsCursor = page.nextCursor;
        _postsHasMore = page.nextCursor != null && page.nextCursor!.isNotEmpty;
        _postsLoading = false;
        _postsLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _postsLoading = false;
        _postsLoadingMore = false;
      });
    }
  }

  Future<void> _loadPostsMore() async {
    if (_postsLoadingMore || !_postsHasMore) return;
    setState(() => _postsLoadingMore = true);
    await _loadPosts(refresh: false);
  }

  String get _displayName {
    if (_profile != null && _profile!.fullName.isNotEmpty) return _profile!.fullName;
    if (_posts.isNotEmpty) return _posts.first.authorSnapshot.fullName;
    return 'Người dùng SYNC';
  }

  String? get _avatarUrl {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
      return _profile!.avatarUrl;
    }
    if (_posts.isNotEmpty) return _posts.first.authorSnapshot.avatarUrl;
    return null;
  }

  String? get _backgroundUrl {
    if (_profile?.backgroundImageUrl != null && _profile!.backgroundImageUrl!.isNotEmpty) {
      return _profile!.backgroundImageUrl;
    }
    return null;
  }

  int get _level => _profile?.currentLevel ?? 10;
  int get _streak => _profile?.currentStreak ?? 14;

  Future<void> _toggleFollow() async {
    if (_followActionLoading) return;
    setState(() => _followActionLoading = true);
    try {
      if (_followStatus.isFollowing || _followStatus.isPending) {
        await _socialRepo.unfollowUser(widget.userId);
        if (!mounted) return;
        setState(() {
          _followStatus = const FollowStatus();
          if (_followCounts.followerCount > 0) {
            _followCounts = FollowCounts(
              followerCount: _followCounts.followerCount - 1,
              followingCount: _followCounts.followingCount,
            );
          }
        });
      } else {
        await _socialRepo.followUser(widget.userId);
        if (!mounted) return;
        setState(() {
          _followStatus = const FollowStatus(outgoingStatus: 'Accepted');
          _followCounts = FollowCounts(
            followerCount: _followCounts.followerCount + 1,
            followingCount: _followCounts.followingCount,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapApiError(e)), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _followActionLoading = false);
    }
  }

  Future<void> _toggleLike(String postId) async {
    final liked = _likedPostIds.contains(postId);
    try {
      if (liked) {
        await _socialRepo.unlikePost(postId);
      } else {
        await _socialRepo.likePost(postId);
      }
      if (!mounted) return;
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = _posts[idx];
      setState(() {
        if (liked) {
          _likedPostIds.remove(postId);
        } else {
          _likedPostIds.add(postId);
        }
        _posts[idx] = post.copyWith(
          isLikedByMe: !liked,
          metrics: SocialPostMetrics(
            likeCount: post.metrics.likeCount + (liked ? -1 : 1),
            commentCount: post.metrics.commentCount,
            shareCount: post.metrics.shareCount,
          ),
        );
      });
    } catch (_) {}
  }

  void _incrementCommentCount(String postId) {
    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = _posts[idx];
    setState(() {
      _posts[idx] = post.copyWith(
        metrics: SocialPostMetrics(
          likeCount: post.metrics.likeCount,
          commentCount: post.metrics.commentCount + 1,
          shareCount: post.metrics.shareCount,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: _ProfileHeader(
              displayName: _displayName,
              avatarUrl: _avatarUrl,
              tagline: 'Fitness Enthusiast',
              coverUrl: _backgroundUrl,
              onBack: () => context.popOrGoHome(),
              followCounts: _followCounts,
              level: _level,
              streak: _streak,
              followStatus: _followStatus,
              followLoading: _followLoading || _followActionLoading,
              onFollow: _toggleFollow,
              onMessage: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tính năng nhắn tin đang phát triển'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyTabBarDelegate(
              TabBar(
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.textPrimary,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Bài viết'),
                  Tab(text: 'Thành tựu'),
                  Tab(text: 'Giới thiệu'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _PostsTab(
              posts: _posts,
              loading: _postsLoading,
              loadingMore: _postsLoadingMore,
              hasMore: _postsHasMore,
              likedIds: _likedPostIds,
              onRefresh: _loadAll,
              onLoadMore: _loadPostsMore,
              onLike: _toggleLike,
              onComment: (id) => SocialCommentsSheet.show(
                context,
                postId: id,
                onCommentCreated: _incrementCommentCount,
              ),
              onShare: (id) {
                final idx = _posts.indexWhere((p) => p.id == id);
                if (idx >= 0) {
                  SocialPostShareSheet.show(context, post: _posts[idx]);
                }
              },
              onMore: (id) {
                final post = _posts.firstWhere((p) => p.id == id, orElse: () => _posts.first);
                SocialPostActionsSheet.show(
                  context,
                  post: post,
                  isOwnPost: false,
                  onHide: () => setState(() => _posts.removeWhere((p) => p.id == id)),
                );
              },
            ),
            _AchievementsTab(level: _level, streak: _streak),
            _AboutTab(
              profile: _profile,
              loading: _profileLoading,
              followCounts: _followCounts,
              onRetry: _loadProfile,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.avatarUrl,
    required this.tagline,
    required this.coverUrl,
    required this.onBack,
    required this.followCounts,
    required this.level,
    required this.streak,
    required this.followStatus,
    required this.followLoading,
    required this.onFollow,
    required this.onMessage,
  });

  final String displayName;
  final String? avatarUrl;
  final String tagline;
  final String? coverUrl;
  final VoidCallback onBack;
  final FollowCounts followCounts;
  final int level;
  final int streak;
  final FollowStatus followStatus;
  final bool followLoading;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  Widget _defaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.lightGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: AppColors.cardBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: _coverHeight + topPad,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      top: topPad,
                      left: 0,
                      right: 0,
                      height: _coverHeight,
                      child: coverUrl != null && coverUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: coverUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.primaryGreen.withValues(alpha: 0.25),
                              ),
                              errorWidget: (_, __, ___) => _defaultCover(),
                            )
                          : _defaultCover(),
                    ),
                    Positioned(
                      top: topPad + 8,
                      left: 4,
                      child: IconButton(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 20,
                bottom: -_avatarRadius,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SyncAvatar(
                    name: displayName,
                    imageUrl: avatarUrl,
                    radius: _avatarRadius,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _avatarRadius + 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _FollowButton(
                        status: followStatus,
                        loading: followLoading,
                        onPressed: onFollow,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.tonal(
                        onPressed: onMessage,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.backgroundAlt,
                          foregroundColor: AppColors.textPrimary,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        child: const Text('Nhắn tin', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _MetricsRow(
                  followers: followCounts.followerCount,
                  following: followCounts.followingCount,
                  level: level,
                  streak: streak,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.status,
    required this.loading,
    required this.onPressed,
  });

  final FollowStatus status;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 44,
        child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (status.isFollowing) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.borderLight),
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('Đang theo dõi', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    if (status.isPending) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: const Text('Đã gửi yêu cầu', style: TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        minimumSize: const Size.fromHeight(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      child: const Text('Theo dõi', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.followers,
    required this.following,
    required this.level,
    required this.streak,
  });

  final int followers;
  final int following;
  final int level;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.8)),
          bottom: BorderSide(color: AppColors.borderLight.withValues(alpha: 0.8)),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _MetricCell(value: _formatCount(followers), label: 'Followers')),
          _divider(),
          Expanded(child: _MetricCell(value: _formatCount(following), label: 'Đang theo dõi')),
          _divider(),
          Expanded(child: _MetricCell(value: 'Lvl $level', label: 'Cấp độ')),
          _divider(),
          Expanded(child: _MetricCell(value: '$streak', label: 'Chuỗi ngày')),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: AppColors.borderLight,
      );
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

String _formatCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

// ─── Sticky TabBar ──────────────────────────────────────────────────────────────

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: AppColors.cardBackground,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}

// ─── Tabs ─────────────────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.likedIds,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onMore,
  });

  final List<SocialPost> posts;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Set<String> likedIds;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final void Function(String) onLike;
  final void Function(String) onComment;
  final void Function(String) onShare;
  final void Function(String) onMore;

  @override
  Widget build(BuildContext context) {
    if (loading && posts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (posts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Chưa có bài viết nào.', style: TextStyle(color: AppColors.textMuted))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (hasMore && scroll.metrics.extentAfter < 320) onLoadMore();
          return false;
        },
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          itemCount: posts.length + (loadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              );
            }
            final post = posts[index];
            return SocialFeedPostCard(
              post: post,
              isLiked: likedIds.contains(post.id),
              onLike: () => onLike(post.id),
              onComment: () => onComment(post.id),
              onShare: () => onShare(post.id),
              onDismiss: () => onMore(post.id),
            );
          },
        ),
      ),
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab({required this.level, required this.streak});

  final int level;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _HighlightBanner(level: level, streak: streak),
        const SizedBox(height: 20),
        const Text(
          'Đang tiến hành',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...AchievementDisplayData.inProgress.map(
          (a) => InProgressAchievementCard(achievement: a),
        ),
        const SizedBox(height: 20),
        const Text(
          'Đã mở khóa',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        ...AchievementDisplayData.unlocked.map(
          (a) => UnlockedAchievementCard(achievement: a),
        ),
      ],
    );
  }
}

class _HighlightBanner extends StatelessWidget {
  const _HighlightBanner({required this.level, required this.streak});

  final int level;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấp $level · $streak ngày streak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tiếp tục tập luyện để mở khóa huy hiệu mới',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
        ],
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.profile,
    required this.loading,
    required this.followCounts,
    required this.onRetry,
  });

  final PublicProfile? profile;
  final bool loading;
  final FollowCounts followCounts;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _AboutCard(
          icon: Icons.person_outline_rounded,
          title: 'Họ tên',
          value: profile?.fullName.isNotEmpty == true ? profile!.fullName : '—',
        ),
        _AboutCard(
          icon: Icons.military_tech_outlined,
          title: 'Cấp độ gamification',
          value: profile != null ? 'Level ${profile!.currentLevel}' : 'Level 10',
        ),
        _AboutCard(
          icon: Icons.bolt_outlined,
          title: 'Kinh nghiệm (XP)',
          value: profile != null ? '${profile!.currentXp} XP' : '2.450 XP',
        ),
        _AboutCard(
          icon: Icons.local_fire_department_outlined,
          title: 'Chuỗi tập luyện',
          value: profile != null ? '${profile!.currentStreak} ngày' : '14 ngày',
        ),
        _AboutCard(
          icon: Icons.people_outline_rounded,
          title: 'Cộng đồng',
          value: '${_formatCount(followCounts.followerCount)} followers · ${_formatCount(followCounts.followingCount)} đang theo dõi',
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Làm mới hồ sơ'),
        ),
      ],
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.lightGreen.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
