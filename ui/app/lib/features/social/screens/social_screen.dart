import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/widgets/social_comments_sheet.dart';
import 'package:sync_app/features/social/widgets/social_post_share_sheet.dart';
import 'package:sync_app/features/social/widgets/social_feed_create_post_row.dart';
import 'package:sync_app/features/social/widgets/social_feed_header.dart';
import 'package:sync_app/features/social/widgets/social_feed_post_card.dart';
import 'package:sync_app/features/social/widgets/social_feed_skeleton.dart';
import 'package:sync_app/features/social/widgets/social_create_story_sheet.dart';
import 'package:sync_app/features/social/widgets/social_stories_row.dart';
import 'package:sync_app/features/social/widgets/social_story_viewer.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SocialCubit(getIt(), getIt())..loadAll(),
      child: const _SocialScreenView(),
    );
  }
}

class _SocialScreenView extends StatefulWidget {
  const _SocialScreenView();

  @override
  State<_SocialScreenView> createState() => _SocialScreenViewState();
}

class _SocialScreenViewState extends State<_SocialScreenView> {
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
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    if (offset >= max - 320) {
      context.read<SocialCubit>().loadMore();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<SocialCubit>().loadAll(refresh: true);
  }

  void _openStory(BuildContext context, SocialCubit cubit, SocialStoryFeedGroup group) {
    SocialStoryViewer.show(
      context,
      group: group,
      onViewed: (story) => cubit.viewStory(story, authorId: group.authorId),
      onLike: (story) => cubit.likeStory(story.id),
    );
  }

  void _openUserProfile(BuildContext context, SocialState state, String userId) {
    if (userId.isEmpty) return;
    if (userId == state.currentUserId) {
      context.go(AppRoutes.profile);
      return;
    }
    context.push(AppRoutes.socialUserProfile(userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SocialCubit, SocialState>(
      listenWhen: (prev, curr) => prev.snackbarError != curr.snackbarError,
      listener: (context, state) {
        final message = state.snackbarError;
        if (message == null || message.isEmpty) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.read<SocialCubit>().clearSnackbarError();
      },
      child: ColoredBox(
        color: AppColors.background,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: _onRefresh,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: SocialFeedHeader()),
                BlocBuilder<SocialCubit, SocialState>(
                  buildWhen: (prev, curr) => prev.currentUser != curr.currentUser,
                  builder: (context, state) {
                    return SliverToBoxAdapter(
                      child: SocialFeedCreatePostRow(user: state.currentUser),
                    );
                  },
                ),
                BlocBuilder<SocialCubit, SocialState>(
                  buildWhen: (prev, curr) =>
                      prev.showStoriesRow != curr.showStoriesRow ||
                      prev.storyGroups != curr.storyGroups ||
                      prev.myStories != curr.myStories ||
                      prev.seenStoryAuthorIds != curr.seenStoryAuthorIds ||
                      prev.currentUser != curr.currentUser,
                  builder: (context, state) {
                    if (!state.showStoriesRow) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    final cubit = context.read<SocialCubit>();
                    return SliverToBoxAdapter(
                      child: SocialStoriesRow(
                        currentUser: state.currentUser,
                        storyGroups: state.storyGroups,
                        myStories: state.myStories,
                        seenAuthorIds: state.seenStoryAuthorIds,
                        onCreateStory: () => SocialCreateStorySheet.show(context),
                        onStoryTap: (group) => _openStory(context, cubit, group),
                      ),
                    );
                  },
                ),
                BlocBuilder<SocialCubit, SocialState>(
                  builder: (context, state) {
                    if (state.status == SocialStatus.loading && state.posts.isEmpty) {
                      return const SocialFeedSkeletonList();
                    }

                    if (state.status == SocialStatus.failure && state.posts.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _FeedErrorCard(
                          message: state.error ?? 'Không thể tải bài viết.',
                          onRetry: () => context.read<SocialCubit>().loadFeed(refresh: true),
                        ),
                      );
                    }

                    final posts = state.visiblePosts;
                    if (posts.isEmpty && state.status == SocialStatus.success) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Chưa có bài viết nào.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
                      sliver: SliverList.separated(
                        itemCount: posts.length + (state.isLoadingMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          if (index >= posts.length) {
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

                          final post = posts[index];
                          final cubit = context.read<SocialCubit>();
                          final isLiked = state.likedPostIds.contains(post.id);

                          return SocialFeedPostCard(
                            post: post,
                            isLiked: isLiked,
                            onLike: () => cubit.toggleLike(post.id),
                            onOpenProfile: (userId) => _openUserProfile(context, state, userId),
                            onComment: () => SocialCommentsSheet.show(
                              context,
                              postId: post.id,
                            ),
                            onShare: () => SocialPostShareSheet.show(
                              context,
                              post: post,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedErrorCard extends StatelessWidget {
  const _FeedErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
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
