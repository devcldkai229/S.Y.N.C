import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/widgets/social_comments_sheet.dart';
import 'package:sync_app/features/social/widgets/social_post_card.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SocialCubit(getIt())..loadFeed(),
      child: const _SocialView(),
    );
  }
}

class _SocialView extends StatelessWidget {
  const _SocialView();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Social',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_rounded, size: 16, color: AppColors.primaryGreen),
                        SizedBox(width: 4),
                        Text(
                          'Community',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Share progress, clips, and tips with the SYNC crew.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: BlocBuilder<SocialCubit, SocialState>(
                builder: (context, state) {
                  if (state.status == SocialStatus.loading && state.posts.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryGreen),
                    );
                  }
                  if (state.status == SocialStatus.failure && state.posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.error ?? 'Failed to load feed'),
                          TextButton(
                            onPressed: () => context.read<SocialCubit>().loadFeed(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primaryGreen,
                    onRefresh: () => context.read<SocialCubit>().loadFeed(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: state.posts.length,
                      itemBuilder: (context, index) {
                        final post = state.posts[index];
                        return SocialPostCard(
                          post: post,
                          onLike: () => context.read<SocialCubit>().toggleLike(post.id),
                          onDislike: () => context.read<SocialCubit>().toggleDislike(post.id),
                          onComment: () => SocialCommentsSheet.show(context, postId: post.id),
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
