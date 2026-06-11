import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

/// Frontend-only search (posts from feed + mock users). Backend wiring later.
class SocialSearchScreen extends StatefulWidget {
  const SocialSearchScreen({super.key});

  @override
  State<SocialSearchScreen> createState() => _SocialSearchScreenState();
}

class _SocialSearchScreenState extends State<SocialSearchScreen>
    with SingleTickerProviderStateMixin {
  final _queryCtrl = TextEditingController();
  late final TabController _tabs;

  static const _mockUsers = [
    _SearchUser(
      id: 'd3b07384-d9a4-4a5c-9742-832103328ce1',
      name: 'SYNC Admin',
      subtitle: 'Coach · SYNC Platform',
      avatarUrl: 'https://i.pravatar.cc/150?u=admin',
    ),
    _SearchUser(
      id: '8f3a5595-6b58-450e-8fb8-228bc7f59041',
      name: 'Khải Nguyễn',
      subtitle: 'Pro Athlete · 21 ngày streak',
      avatarUrl: 'https://i.pravatar.cc/150?u=khai',
    ),
    _SearchUser(
      id: '114ab811-1a3f-4e0d-b4f0-b8d9eb93cd84',
      name: 'Trần Thể Lực',
      subtitle: 'Beginner · Foundation roadmap',
      avatarUrl: 'https://i.pravatar.cc/150?u=tran',
    ),
    _SearchUser(
      id: 'c55ef9c8-251c-4cf2-8cb2-e3e8f85cb159',
      name: 'Lê Dinh Dưỡng',
      subtitle: 'Nutritionist · Meal tips',
      avatarUrl: 'https://i.pravatar.cc/150?u=le',
    ),
    _SearchUser(
      id: '9081db2b-f3b3-4610-85f4-3d601d51a6fb',
      name: 'Phạm Cardio',
      subtitle: 'Active Member · Cardio lover',
      avatarUrl: 'https://i.pravatar.cc/150?u=pham',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _queryCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _tabs.dispose();
    super.dispose();
  }

  String get _query => _queryCtrl.text.trim().toLowerCase();

  List<SocialPost> _filterPosts(List<SocialPost> posts) {
    if (_query.isEmpty) return posts;
    return posts.where((p) {
      final content = p.content.toLowerCase();
      final author = p.authorSnapshot.fullName.toLowerCase();
      return content.contains(_query) || author.contains(_query);
    }).toList();
  }

  List<_SearchUser> _filterUsers() {
    if (_query.isEmpty) return _mockUsers;
    return _mockUsers.where((u) {
      return u.name.toLowerCase().contains(_query) ||
          u.subtitle.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.select((SocialCubit c) => c.state.posts);
    final filteredPosts = _filterPosts(posts);
    final filteredUsers = _filterUsers();

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
          _PostsTab(posts: filteredPosts, query: _query),
          _UsersTab(users: filteredUsers, query: _query),
        ],
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({required this.posts, required this.query});

  final List<SocialPost> posts;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty && posts.isEmpty) {
      return _EmptyState(
        icon: Icons.article_outlined,
        message: 'Không tìm thấy bài viết cho "$query"',
      );
    }

    if (posts.isEmpty) {
      return const _EmptyState(
        icon: Icons.feed_outlined,
        message: 'Gõ từ khóa để lọc bài viết trong feed hiện tại.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final post = posts[index];
        return Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: SyncAvatar(
              name: post.authorSnapshot.fullName,
              imageUrl: post.authorSnapshot.avatarUrl,
              radius: 22,
            ),
            title: Text(
              post.authorSnapshot.fullName,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab({required this.users, required this.query});

  final List<_SearchUser> users;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (query.isNotEmpty && users.isEmpty) {
      return _EmptyState(
        icon: Icons.person_search_outlined,
        message: 'Không tìm thấy người dùng cho "$query"',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = users[index];
        return Material(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            onTap: () => context.push(AppRoutes.socialUserProfile(user.id)),
            leading: SyncAvatar(name: user.name, imageUrl: user.avatarUrl, radius: 24),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Text(
              user.subtitle,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ),
        );
      },
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

class _SearchUser {
  const _SearchUser({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String subtitle;
  final String avatarUrl;
}
