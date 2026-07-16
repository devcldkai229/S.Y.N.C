import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/media_url_resolver.dart';
import 'package:sync_app/features/blogs/cubit/blog_detail_cubit.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class BlogDetailScreen extends StatelessWidget {
  const BlogDetailScreen({super.key, required this.blogId});

  final String blogId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BlogDetailCubit(getIt(), blogId)..load(),
      child: const _BlogDetailView(),
    );
  }
}

class _BlogDetailView extends StatefulWidget {
  const _BlogDetailView();

  @override
  State<_BlogDetailView> createState() => _BlogDetailViewState();
}

class _BlogDetailViewState extends State<_BlogDetailView> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    String? name;
    String? avatar;
    try {
      final settings = await getIt<ProfileApiService>().getProfileSettings();
      name = settings.basic.fullName;
      avatar = settings.basic.avatarUrl;
    } catch (_) {}

    if (!mounted) return;

    try {
      await context.read<BlogDetailCubit>().submitComment(
            content: text,
            authorFullName: name,
            authorAvatarUrl: avatar,
          );
      _commentController.clear();
      _commentFocus.unfocus();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), behavior: SnackBarBehavior.floating),
      );
    }
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
            'Chi tiết',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: BlocBuilder<BlogDetailCubit, BlogDetailState>(
          builder: (context, state) {
            if (state.status == BlogDetailStatus.loading && state.blog == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }

            if (state.status == BlogDetailStatus.failure && state.blog == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.error ?? 'Không tải được bài viết.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => context.read<BlogDetailCubit>().load(),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final blog = state.blog!;
            final cover = MediaUrlResolver.resolve(blog.coverImageUrl) ?? blog.coverImageUrl;
            final date = blog.publishedAt ?? blog.createdAt;
            final dateLabel =
                date == null ? '' : DateFormat('d MMMM yyyy', 'vi').format(date);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
                    children: [
                      if (cover.isNotEmpty)
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: AppColors.lightGreen),
                            errorWidget: (_, __, ___) =>
                                Container(color: AppColors.lightGreen),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              blog.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                SyncAvatar(
                                  name: blog.authorSnapshot.fullName,
                                  imageUrl: blog.authorSnapshot.avatarUrl,
                                  radius: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        blog.authorSnapshot.fullName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (dateLabel.isNotEmpty)
                                        Text(
                                          dateLabel,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: state.isLiking || blog.isLikedByMe
                                      ? null
                                      : () => context.read<BlogDetailCubit>().like(),
                                  icon: Icon(
                                    blog.isLikedByMe
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: blog.isLikedByMe
                                        ? Colors.redAccent
                                        : AppColors.textMuted,
                                  ),
                                ),
                                Text(
                                  '${blog.likeCount}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (blog.tags.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: blog.tags.map((tag) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.lightGreenSoft,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryGreen,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Html(
                              data: blog.content,
                              style: {
                                'body': Style(
                                  margin: Margins.zero,
                                  padding: HtmlPaddings.zero,
                                  fontSize: FontSize(15),
                                  color: AppColors.textSecondary,
                                  lineHeight: const LineHeight(1.55),
                                ),
                                'h2': Style(
                                  fontSize: FontSize(20),
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  margin: Margins.only(top: 16, bottom: 8),
                                ),
                                'h3': Style(
                                  fontSize: FontSize(17),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                  margin: Margins.only(top: 12, bottom: 6),
                                ),
                                'p': Style(margin: Margins.only(bottom: 10)),
                                'li': Style(margin: Margins.only(bottom: 4)),
                                'strong': Style(fontWeight: FontWeight.w700),
                              },
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 12),
                            Text(
                              'Bình luận (${blog.commentCount})',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (state.comments.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Chưa có bình luận. Hãy là người đầu tiên!',
                                  style: TextStyle(color: AppColors.textMuted),
                                ),
                              )
                            else
                              ...state.comments.map((c) => _CommentTile(comment: c)),
                            if (state.commentsHasMore)
                              TextButton(
                                onPressed: () =>
                                    context.read<BlogDetailCubit>().loadMoreComments(),
                                child: const Text('Xem thêm bình luận'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _commentFocus,
                            minLines: 1,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Viết bình luận…',
                              filled: true,
                              fillColor: AppColors.background,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: state.isSubmittingComment ? null : _sendComment,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                          ),
                          icon: state.isSubmittingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final BlogComment comment;

  @override
  Widget build(BuildContext context) {
    final name = comment.authorSnapshot?.fullName ?? 'Người dùng';
    final avatar = comment.authorSnapshot?.avatarUrl;
    final time = DateFormat('d MMM · HH:mm', 'vi').format(comment.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SyncAvatar(name: name, imageUrl: avatar, radius: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
