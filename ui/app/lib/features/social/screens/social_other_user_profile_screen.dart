import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/screens/social_image_viewer_screen.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/social/utils/social_media_utils.dart';
import 'package:sync_app/features/social/widgets/social_comments_sheet.dart';
import 'package:sync_app/features/social/widgets/social_post_card.dart';

class SocialOtherUserProfileScreen extends StatefulWidget {
  const SocialOtherUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  State<SocialOtherUserProfileScreen> createState() =>
      _SocialOtherUserProfileScreenState();
}

class _SocialOtherUserProfileScreenState extends State<SocialOtherUserProfileScreen>
    with SingleTickerProviderStateMixin {
  final SocialRepository _socialRepo = getIt<SocialRepository>();
  final ProfileApiService _profileApi = getIt<ProfileApiService>();

  static const _pageLimit = 20;

  late final TabController _tabController;

  PublicProfile? _profile;
  bool _profileLoading = true;
  String? _profileError;

  final List<SocialPost> _feedPosts = [];
  final List<SocialPost> _mediaPosts = [];
  bool _feedLoading = false;
  bool _mediaLoading = false;
  bool _feedLoadingMore = false;
  bool _mediaLoadingMore = false;
  String? _feedCursor;
  String? _mediaCursor;
  bool _feedHasMore = false;
  bool _mediaHasMore = false;

  final Set<String> _likedPostIds = {};
  final Set<String> _sharedPostIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadProfile();
    _loadFeed(refresh: true);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if ((index == 1 || index == 2) && _mediaPosts.isEmpty) {
      _loadMedia(refresh: true);
    }
  }

  Future<void> _loadProfile() async {
    if (widget.userId.isEmpty) {
      setState(() {
        _profileLoading = false;
        _profileError = 'Invalid user id.';
      });
      return;
    }

    setState(() {
      _profileLoading = true;
      _profileError = null;
    });
    try {
      final profile = await _profileApi.getPublicProfile(widget.userId);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _profileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // IAM public profile is optional — wall posts can still load.
      setState(() {
        _profileLoading = false;
        _profileError = e.toString();
      });
    }
  }

  Future<void> _loadFeed({required bool refresh}) async {
    if (!mounted) return;
    setState(() {
      _feedLoading = refresh;
      if (refresh) {
        _feedPosts.clear();
        _feedCursor = null;
        _feedHasMore = false;
      }
    });

    try {
      final page = await _socialRepo.loadUserWall(
        userId: widget.userId,
        cursor: refresh ? null : _feedCursor,
        limit: _pageLimit,
        onlyMedia: false,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _feedPosts
            ..clear()
            ..addAll(page.items);
        } else {
          _feedPosts.addAll(page.items);
        }
        _feedCursor = page.nextCursor;
        _feedHasMore = page.nextCursor != null && page.nextCursor!.isNotEmpty;
        _feedLoading = false;
        _feedLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedLoading = false;
        _feedLoadingMore = false;
      });
    }
  }

  Future<void> _loadFeedMore() async {
    if (_feedLoadingMore || !_feedHasMore) return;
    setState(() => _feedLoadingMore = true);
    await _loadFeed(refresh: false);
  }

  Future<void> _loadMedia({required bool refresh}) async {
    if (!mounted) return;
    setState(() {
      _mediaLoading = refresh;
      if (refresh) {
        _mediaPosts.clear();
        _mediaCursor = null;
        _mediaHasMore = false;
      }
    });

    try {
      final page = await _socialRepo.loadUserWall(
        userId: widget.userId,
        cursor: refresh ? null : _mediaCursor,
        limit: _pageLimit,
        onlyMedia: true,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _mediaPosts
            ..clear()
            ..addAll(page.items);
        } else {
          _mediaPosts.addAll(page.items);
        }
        _mediaCursor = page.nextCursor;
        _mediaHasMore = page.nextCursor != null && page.nextCursor!.isNotEmpty;
        _mediaLoading = false;
        _mediaLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _mediaLoading = false;
        _mediaLoadingMore = false;
      });
    }
  }

  Future<void> _loadMediaMore() async {
    if (_mediaLoadingMore || !_mediaHasMore) return;
    setState(() => _mediaLoadingMore = true);
    await _loadMedia(refresh: false);
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadProfile(),
      _loadFeed(refresh: true),
      _loadMedia(refresh: true),
    ]);
  }

  String get _displayName {
    if (_profile != null && _profile!.fullName.isNotEmpty) return _profile!.fullName;
    if (_feedPosts.isNotEmpty) return _feedPosts.first.authorSnapshot.fullName;
    return 'User Profile';
  }

  String? get _avatarUrl {
    if (_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty) {
      return _profile!.avatarUrl;
    }
    if (_feedPosts.isNotEmpty) return _feedPosts.first.authorSnapshot.avatarUrl;
    return null;
  }

  void _openProfile(String otherUserId) {
    if (otherUserId.isEmpty || otherUserId == widget.userId) return;
    context.push(AppRoutes.socialUserProfile(otherUserId));
  }

  Future<void> _handleLike(String postId, List<SocialPost> target) async {
    if (_likedPostIds.contains(postId)) return;
    try {
      await _socialRepo.likePost(postId);
      if (!mounted) return;
      final idx = target.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = target[idx];
      setState(() {
        _likedPostIds.add(postId);
        target[idx] = post.copyWith(
          isLikedByMe: true,
          metrics: SocialPostMetrics(
            likeCount: post.metrics.likeCount + 1,
            commentCount: post.metrics.commentCount,
            shareCount: post.metrics.shareCount,
          ),
        );
      });
    } catch (_) {}
  }

  Future<void> _handleShare(String postId, List<SocialPost> target) async {
    if (_sharedPostIds.contains(postId)) return;
    try {
      await _socialRepo.sharePost(postId);
      if (!mounted) return;
      final idx = target.indexWhere((p) => p.id == postId);
      if (idx < 0) return;
      final post = target[idx];
      setState(() {
        _sharedPostIds.add(postId);
        target[idx] = post.copyWith(
          isSharedByMe: true,
          metrics: SocialPostMetrics(
            likeCount: post.metrics.likeCount,
            commentCount: post.metrics.commentCount,
            shareCount: post.metrics.shareCount + 1,
          ),
        );
      });
    } catch (_) {}
  }

  void _incrementCommentCount(String postId, List<SocialPost> target) {
    final idx = target.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    final post = target[idx];
    setState(() {
      target[idx] = post.copyWith(
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(_displayName),
      ),
      body: Column(
        children: [
          _ProfileHeader(
            displayName: _displayName,
            avatarUrl: _avatarUrl,
            profile: _profile,
            loading: _profileLoading,
            postCount: _feedPosts.length,
          ),
          Material(
            color: AppColors.background,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primaryGreen,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primaryGreen,
              tabs: const [
                Tab(text: 'Posts'),
                Tab(text: 'Photos'),
                Tab(text: 'Videos'),
                Tab(text: 'About'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _PostsTab(
                  posts: _feedPosts,
                  loading: _feedLoading,
                  loadingMore: _feedLoadingMore,
                  hasMore: _feedHasMore,
                  onRefresh: () => _refreshAll(),
                  onLoadMore: _loadFeedMore,
                  likedIds: _likedPostIds,
                  sharedIds: _sharedPostIds,
                  onLike: (id) => _handleLike(id, _feedPosts),
                  onShare: (id) => _handleShare(id, _feedPosts),
                  onComment: (id) => SocialCommentsSheet.show(
                    context,
                    postId: id,
                    onCommentCreated: (pid) => _incrementCommentCount(pid, _feedPosts),
                  ),
                  onOpenProfile: _openProfile,
                ),
                _PhotosTab(
                  posts: _mediaPosts,
                  loading: _mediaLoading,
                  loadingMore: _mediaLoadingMore,
                  hasMore: _mediaHasMore,
                  onRefresh: () => _loadMedia(refresh: true),
                  onLoadMore: _loadMediaMore,
                ),
                _VideosTab(
                  posts: videoPostsFrom(_mediaPosts.isNotEmpty ? _mediaPosts : _feedPosts),
                  loading: _mediaLoading && _mediaPosts.isEmpty,
                  onRefresh: () => _loadMedia(refresh: true),
                ),
                _AboutTab(
                  profile: _profile,
                  loading: _profileLoading,
                  error: _profileError,
                  onRetry: _loadProfile,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.avatarUrl,
    required this.profile,
    required this.loading,
    required this.postCount,
  });

  final String displayName;
  final String? avatarUrl;
  final PublicProfile? profile;
  final bool loading;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGreen, AppColors.lightGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.lightGreen,
                  backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl!)
                      : null,
                  child: avatarUrl == null || avatarUrl!.isEmpty
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (profile != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Level ${profile!.currentLevel} · ${profile!.currentXp} XP · ${profile!.currentStreak} day streak',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '$postCount public posts',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
    required this.likedIds,
    required this.sharedIds,
    required this.onLike,
    required this.onShare,
    required this.onComment,
    required this.onOpenProfile,
  });

  final List<SocialPost> posts;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final Set<String> likedIds;
  final Set<String> sharedIds;
  final void Function(String) onLike;
  final void Function(String) onShare;
  final void Function(String) onComment;
  final void Function(String) onOpenProfile;

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
            SizedBox(height: 120),
            Center(child: Text('No posts yet.', style: TextStyle(color: AppColors.textMuted))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (scroll.metrics.extentAfter < 300) onLoadMore();
          return false;
        },
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          itemCount: posts.length + (loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= posts.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final post = posts[index];
            return SocialPostCard(
              post: post,
              isLikedByMe: likedIds.contains(post.id),
              isSharedByMe: sharedIds.contains(post.id),
              onLike: () => onLike(post.id),
              onShare: () => onShare(post.id),
              onComment: () => onComment(post.id),
              onOpenProfile: onOpenProfile,
            );
          },
        ),
      ),
    );
  }
}

class _PhotosTab extends StatelessWidget {
  const _PhotosTab({
    required this.posts,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final List<SocialPost> posts;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final images = imageUrlsFromPosts(posts);

    if (loading && images.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (images.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primaryGreen,
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No photos yet.', style: TextStyle(color: AppColors.textMuted))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (scroll) {
          if (hasMore && scroll.metrics.extentAfter < 300) onLoadMore();
          return false;
        },
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: images.length + (loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= images.length) {
              return const Center(child: CircularProgressIndicator());
            }
            final url = images[index];
            return GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SocialImageViewerScreen(
                    imageUrls: images,
                    initialIndex: index,
                  ),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ColoredBox(
                    color: AppColors.lightGreen.withValues(alpha: 0.3),
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const ColoredBox(
                    color: AppColors.backgroundAlt,
                    child: Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  const _VideosTab({
    required this.posts,
    required this.loading,
    required this.onRefresh,
  });

  final List<SocialPost> posts;
  final bool loading;
  final Future<void> Function() onRefresh;

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
            SizedBox(height: 120),
            Center(child: Text('No videos yet.', style: TextStyle(color: AppColors.textMuted))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          final videoUrl = post.mediaUrls.firstWhere(socialUrlIsVideo, orElse: () => '');
          if (videoUrl.isEmpty) return const SizedBox.shrink();

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SocialVideoPlayerScreen(videoUrl: videoUrl),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(color: Colors.black.withValues(alpha: 0.85)),
                        const Center(
                          child: Icon(Icons.play_circle_fill, size: 56, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  if (post.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({
    required this.profile,
    required this.loading,
    required this.error,
    required this.onRetry,
  });

  final PublicProfile? profile;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Could not load profile info.', style: TextStyle(color: AppColors.textMuted)),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (profile == null) {
      return const Center(child: Text('No profile details.', style: TextStyle(color: AppColors.textMuted)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
      children: [
        _AboutTile(icon: Icons.person_outline, label: 'Name', value: profile!.fullName),
        _AboutTile(icon: Icons.military_tech_outlined, label: 'Level', value: '${profile!.currentLevel}'),
        _AboutTile(icon: Icons.star_outline, label: 'Experience', value: '${profile!.currentXp} XP'),
        _AboutTile(icon: Icons.local_fire_department_outlined, label: 'Current streak', value: '${profile!.currentStreak} days'),
        const SizedBox(height: 16),
        const Text(
          'Public gamification stats from Sync IAM. More profile fields (bio, location) can be added when the API exposes them.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
