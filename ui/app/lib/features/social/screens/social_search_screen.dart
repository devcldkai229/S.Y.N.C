import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/widgets/social_comments_sheet.dart';
import 'package:sync_app/features/social/widgets/social_feed_post_card.dart';
import 'package:sync_app/features/social/widgets/social_feed_skeleton.dart';
import 'package:sync_app/features/social/widgets/social_post_share_sheet.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class SocialSearchScreen extends StatefulWidget {
  const SocialSearchScreen({super.key});

  @override
  State<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends State<SocialSearchScreen>
    with SingleTickerProviderStateMixin {
  static const _debounceMs = 300;
  static const _pageSize = 20;
  static const _minQueryLength = 2;

  final _queryCtrl = TextEditingController();
  final _socialRepo = getIt<SocialRepository>();
  late final TabController _tabs;

  Timer? _debounce;
  int _searchGeneration = 0;

  // Posts tab
  final List<SocialPost> _posts = [];
  final Set<String> _likedPostIds = {};
  bool _postsLoading = false;
  bool _postsLoadingMore = false;
  int _postsPage = 1;
  bool _postsHasMore = false;
  String? _postsError;

  // Users tab
  final List<UserSearchResult> _users = [];
  bool _usersLoading = false;
  bool _usersLoadingMore = false;
  int _usersPage = 1;
  bool _usersHasMore = false;
  String? _usersError;
  final Set<String> _followActionUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTabChanged);
    _queryCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl
      ..removeListener(_onQueryChanged)
      ..dispose();
    _tabs
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  String get _query => _queryCtrl.text.trim();

  void _onQueryChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), _runActiveSearch);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    _runActiveSearch();
  }

  void _runActiveSearch() {
    if (_tabs.index == 0) {
      _searchPosts(refresh: true);
    } else {
      _searchUsers(refresh: true);
    }
  }

  Future<void> _searchPosts({required bool refresh}) async {
    final query = _query;
    if (query.length < _minQueryLength) {
      setState(() {
        _posts
          ..clear()
          ..addAll([]);
        _likedPostIds.clear();
        _postsLoading = false;
        _postsLoadingMore = false;
        _postsHasMore = false;
        _postsError = null;
        _postsPage = 1;
      });
      return;
    }

    final generation = ++_searchGeneration;
    final pageNumber = refresh ? 1 : _postsPage + 1;

    setState(() {
      _postsError = null;
      if (refresh) {
        _postsLoading = true;
        _postsLoadingMore = false;
        _postsPage = 1;
        _postsHasMore = false;
      } else {
        _postsLoadingMore = true;
      }
    });

    try {
      final page = await _socialRepo.searchPosts(
        query: query,
        pageNumber: pageNumber,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        if (refresh) {
          _posts
            ..clear()
            ..addAll(page.items);
        } else {
          _posts.addAll(page.items);
        }
        for (final post in page.items) {
          if (post.isLikedByMe) _likedPostIds.add(post.id);
        }
        _postsPage = page.pageNumber;
        _postsHasMore = page.hasNextPage;
        _postsLoading = false;
        _postsLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _postsError = mapApiError(e);
        _postsLoading = false;
        _postsLoadingMore = false;
      });
    }
  }

  Future<void> _searchUsers({required bool refresh}) async {
    final query = _query;
    if (query.length < _minQueryLength) {
      setState(() {
        _users.clear();
        _usersLoading = false;
        _usersLoadingMore = false;
        _usersHasMore = false;
        _usersError = null;
        _usersPage = 1;
      });
      return;
    }

    final generation = ++_searchGeneration;
    final pageNumber = refresh ? 1 : _usersPage + 1;

    setState(() {
      _usersError = null;
      if (refresh) {
        _usersLoading = true;
        _usersLoadingMore = false;
        _usersPage = 1;
        _usersHasMore = false;
      } else {
        _usersLoadingMore = true;
      }
    });

    try {
      final page = await _socialRepo.searchUsers(
        query: query,
        pageNumber: pageNumber,
        pageSize: _pageSize,
      );
      if (!mounted || generation != _searchGeneration) return;

      setState(() {
        if (refresh) {
          _users
            ..clear()
            ..addAll(page.items);
        } else {
          _users.addAll(page.items);
        }
        _usersPage = page.pageNumber;
        _usersHasMore = page.hasNextPage;
        _usersLoading = false;
        _usersLoadingMore = false;
      });
    } catch (e) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _usersError = mapApiError(e);
        _usersLoading = false;
        _usersLoadingMore = false;
      });
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapApiError(e)), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _toggleFollow(UserSearchResult user) async {
    if (_followActionUserIds.contains(user.id)) return;
    setState(() => _followActionUserIds.add(user.id));
    try {
      if (user.isFollowing || user.isPending) {
        await _socialRepo.unfollowUser(user.id);
        if (!mounted) return;
        _updateUserFollowState(
          user.id,
          (current) => UserSearchResult(
            id: current.id,
            fullName: current.fullName,
            avatarUrl: current.avatarUrl,
            canFollow: true,
          ),
        );
      } else {
        await _socialRepo.followUser(user.id);
        final status = await _socialRepo.loadFollowStatus(user.id);
        if (!mounted) return;
        _updateUserFollowState(
          user.id,
          (current) => current.copyWith(
            outgoingStatus: status.outgoingStatus,
            canFollow: status.canFollow,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapApiError(e)), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _followActionUserIds.remove(user.id));
    }
  }

  void _updateUserFollowState(
    String userId,
    UserSearchResult Function(UserSearchResult current) update,
  ) {
    final idx = _users.indexWhere((u) => u.id == userId);
    if (idx < 0) return;
    setState(() => _users[idx] = update(_users[idx]));
  }

  void _openUserProfile(String userId) {
    if (userId.isEmpty) return;
    context.push(AppRoutes.socialUserProfile(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _queryCtrl,
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm bài viết, người dùng...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
            border: InputBorder.none,
            isDense: true,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              onPressed: () => _queryCtrl.clear(),
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryGreen,
          tabs: const [
            Tab(text: 'Bài viết'),
            Tab(text: 'Người dùng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PostsTab(
            query: _query,
            posts: _posts,
            likedPostIds: _likedPostIds,
            loading: _postsLoading,
            loadingMore: _postsLoadingMore,
            hasMore: _postsHasMore,
            error: _postsError,
            onRetry: () => _searchPosts(refresh: true),
            onLoadMore: () => _searchPosts(refresh: false),
            onLike: _toggleLike,
            onOpenProfile: _openUserProfile,
          ),
          _UsersTab(
            query: _query,
            users: _users,
            loading: _usersLoading,
            loadingMore: _usersLoadingMore,
            hasMore: _usersHasMore,
            error: _usersError,
            followActionUserIds: _followActionUserIds,
            onRetry: () => _searchUsers(refresh: true),
            onLoadMore: () => _searchUsers(refresh: false),
            onToggleFollow: _toggleFollow,
            onOpenProfile: _openUserProfile,
          ),
        ],
      ),
    );
  }
}

class _PostsTab extends StatefulWidget {
  const _PostsTab({
    required this.query,
    required this.posts,
    required this.likedPostIds,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.error,
    required this.onRetry,
    required this.onLoadMore,
    required this.onLike,
    required this.onOpenProfile,
  });

  final String query;
  final List<SocialPost> posts;
  final Set<String> likedPostIds;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final Future<void> Function(String postId) onLike;
  final void Function(String userId) onOpenProfile;

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.loadingMore || !widget.hasMore) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 240) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null && widget.posts.isEmpty) {
      return _SearchErrorState(message: widget.error!, onRetry: widget.onRetry);
    }

    if (widget.query.length < 2) {
      return const _EmptyState(
        icon: Icons.search_rounded,
        message: 'Gõ từ khóa để tìm bài viết...',
      );
    }

    if (widget.loading && widget.posts.isEmpty) {
      return const SocialFeedSkeletonList();
    }

    if (!widget.loading && widget.posts.isEmpty) {
      return _EmptyState(
        icon: Icons.article_outlined,
        message: 'Không tìm thấy bài viết cho "${widget.query}"',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: widget.posts.length + (widget.loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= widget.posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final post = widget.posts[index];
        final isLiked = widget.likedPostIds.contains(post.id);

        return SocialFeedPostCard(
          post: post,
          isLiked: isLiked,
          onLike: () => widget.onLike(post.id),
          onOpenProfile: widget.onOpenProfile,
          onComment: () => SocialCommentsSheet.show(context, postId: post.id),
          onShare: () => SocialPostShareSheet.show(context, post: post),
        );
      },
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab({
    required this.query,
    required this.users,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.error,
    required this.followActionUserIds,
    required this.onRetry,
    required this.onLoadMore,
    required this.onToggleFollow,
    required this.onOpenProfile,
  });

  final String query;
  final List<UserSearchResult> users;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final Set<String> followActionUserIds;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final Future<void> Function(UserSearchResult user) onToggleFollow;
  final void Function(String userId) onOpenProfile;

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || widget.loadingMore || !widget.hasMore) return;
    final max = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= max - 240) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.error != null && widget.users.isEmpty) {
      return _SearchErrorState(message: widget.error!, onRetry: widget.onRetry);
    }

    if (widget.query.length < 2) {
      return const _EmptyState(
        icon: Icons.person_search_outlined,
        message: 'Gõ từ khóa để tìm người dùng...',
      );
    }

    if (widget.loading && widget.users.isEmpty) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => _UserRowSkeleton(),
      );
    }

    if (!widget.loading && widget.users.isEmpty) {
      return _EmptyState(
        icon: Icons.person_search_outlined,
        message: 'Không tìm thấy người dùng cho "${widget.query}"',
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: widget.users.length + (widget.loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= widget.users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final user = widget.users[index];
        final actionLoading = widget.followActionUserIds.contains(user.id);

        return Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            onTap: () => widget.onOpenProfile(user.id),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: SyncAvatar(name: user.fullName, imageUrl: user.avatarUrl, radius: 24),
            title: Text(
              user.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            trailing: _FollowChip(
              user: user,
              loading: actionLoading,
              onPressed: user.canFollow || user.isFollowing || user.isPending
                  ? () => widget.onToggleFollow(user)
                  : null,
            ),
          ),
        );
      },
    );
  }
}

class _FollowChip extends StatelessWidget {
  const _FollowChip({
    required this.user,
    required this.loading,
    required this.onPressed,
  });

  final UserSearchResult user;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final label = user.isFollowing
        ? 'Đã theo dõi'
        : user.isPending
            ? 'Đang chờ'
            : 'Theo dõi';

    final isPrimary = !user.isFollowing && !user.isPending;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: isPrimary ? AppColors.primaryGreen : AppColors.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}

class _UserRowSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(12),
      child: const ListTile(
        leading: CircleAvatar(radius: 24, backgroundColor: AppColors.borderLight),
        title: SizedBox(
          height: 14,
          width: 140,
          child: DecoratedBox(decoration: BoxDecoration(color: AppColors.borderLight)),
        ),
        trailing: SizedBox(
          width: 64,
          height: 28,
          child: DecoratedBox(decoration: BoxDecoration(color: AppColors.borderLight)),
        ),
      ),
    );
  }
}

class _SearchErrorState extends StatelessWidget {
  const _SearchErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
