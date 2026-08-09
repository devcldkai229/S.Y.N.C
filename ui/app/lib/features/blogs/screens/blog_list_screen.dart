import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/blogs/cubit/blog_list_cubit.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BlogListCubit(getIt())..load(),
      child: const _BlogListView(),
    );
  }
}

class _BlogListView extends StatefulWidget {
  const _BlogListView();

  @override
  State<_BlogListView> createState() => _BlogListViewState();
}

class _BlogListViewState extends State<_BlogListView> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BlogListCubit>().loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppShellOverlayScaffold(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text(
            'Blogs',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: TextField(
                controller: _searchController,
                onChanged: context.read<BlogListCubit>().onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Tìm bài viết…',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.primaryGreen, width: 1.4),
                  ),
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<BlogListCubit, BlogListState>(
                builder: (context, state) {
                  if (state.status == BlogListStatus.loading && state.items.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    );
                  }

                  if (state.status == BlogListStatus.failure && state.items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.error_outline_rounded,
                      title: 'Không tải được blogs',
                      subtitle: state.error ?? 'Thử lại sau.',
                      actionLabel: 'Thử lại',
                      onAction: () => context.read<BlogListCubit>().load(),
                    );
                  }

                  if (state.items.isEmpty) {
                    return _EmptyState(
                      icon: Icons.article_outlined,
                      title: state.query.isEmpty ? 'Chưa có bài viết' : 'Không tìm thấy',
                      subtitle: state.query.isEmpty
                          ? 'Các bài blog mới sẽ xuất hiện tại đây.'
                          : 'Thử từ khóa khác nhé.',
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<BlogListCubit>().refresh(),
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(color: AppColors.primaryGreen),
                            ),
                          );
                        }
                        final blog = state.items[index];
                        return _BlogCard(
                          blog: blog,
                          onTap: () => context.push(AppRoutes.blogDetail(blog.id)),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.blog, required this.onTap});

  final BlogPost blog;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cover = MediaUrlResolver.resolve(blog.coverImageUrl) ?? blog.coverImageUrl;
    final date = blog.publishedAt ?? blog.createdAt;
    final dateLabel = date == null ? '' : DateFormat('d MMM yyyy', 'vi').format(date);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: cover.isEmpty
                  ? Container(color: AppColors.lightGreen)
                  : CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      placeholder: (_, __) => Container(color: AppColors.lightGreen),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.lightGreen,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_outlined, color: AppColors.textMuted),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SyncAvatar(
                        name: blog.authorSnapshot.fullName,
                        imageUrl: blog.authorSnapshot.avatarUrl,
                        radius: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          blog.authorSnapshot.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                  if (blog.tags.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: blog.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.lightGreenSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.favorite_border_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${blog.likeCount}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(width: 14),
                      Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('${blog.commentCount}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
