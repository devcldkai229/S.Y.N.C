import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/social/models/follow_models.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

enum SocialFollowListMode { followers, following }

class SocialFollowListScreen extends StatefulWidget {
  const SocialFollowListScreen({
    super.key,
    required this.userId,
    required this.mode,
  });

  final String userId;
  final SocialFollowListMode mode;

  @override
  State<SocialFollowListScreen> createState() => _SocialFollowListScreenState();
}

class _SocialFollowListScreenState extends State<SocialFollowListScreen> {
  static const _pageSize = 20;

  final _socialRepo = getIt<SocialRepository>();
  final _scrollCtrl = ScrollController();

  final List<FollowListItem> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = false;
  String? _error;

  String get _title =>
      widget.mode == SocialFollowListMode.followers ? 'Người theo dõi' : 'Đang theo dõi';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load(refresh: true);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }

    try {
      final page = await _fetchPage(1);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _page = page.pageNumber;
        _hasMore = page.hasNextPage;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = mapApiError(e);
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final page = await _fetchPage(nextPage);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _page = page.pageNumber;
        _hasMore = page.hasNextPage;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mapApiError(e))),
      );
    }
  }

  Future<PagedSearchPage<FollowListItem>> _fetchPage(int pageNumber) {
    if (widget.mode == SocialFollowListMode.followers) {
      return _socialRepo.loadFollowers(
        userId: widget.userId,
        pageNumber: pageNumber,
        pageSize: _pageSize,
      );
    }
    return _socialRepo.loadFollowing(
      userId: widget.userId,
      pageNumber: pageNumber,
      pageSize: _pageSize,
    );
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    context.push(AppRoutes.socialUserProfile(userId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _load(refresh: true),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          widget.mode == SocialFollowListMode.followers
              ? 'Chưa có người theo dõi'
              : 'Chưa theo dõi ai',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryGreen,
      onRefresh: () => _load(refresh: true),
      child: ListView.separated(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _items.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ),
            );
          }

          final item = _items[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            leading: SyncAvatar(
              name: item.fullName,
              imageUrl: item.avatarUrl,
              radius: 22,
            ),
            title: Text(
              item.fullName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            onTap: () => _openProfile(item.userId),
          );
        },
      ),
    );
  }
}
