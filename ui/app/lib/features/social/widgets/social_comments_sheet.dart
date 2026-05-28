import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/core/utils/injection.dart';

class SocialCommentsSheet extends StatefulWidget {
  const SocialCommentsSheet({super.key, required this.postId, this.onCommentCreated});

  final String postId;
  final void Function(String postId)? onCommentCreated;

  static Future<void> show(
    BuildContext context, {
    required String postId,
    void Function(String postId)? onCommentCreated,
  }) {
    final cubit = context.read<SocialCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: SocialCommentsSheet(
          postId: postId,
          onCommentCreated: onCommentCreated,
        ),
      ),
    );
  }

  @override
  State<SocialCommentsSheet> createState() => _SocialCommentsSheetState();
}

class _SocialCommentsSheetState extends State<SocialCommentsSheet> {
  final _controller = TextEditingController();
  bool _sending = false;

  final _repo = getIt<SocialRepository>();
  final _profileApi = getIt<ProfileApiService>();

  SocialAuthorSnapshot? _authorSnapshot;
  List<SocialComment> _comments = const [];
  int _pageNumber = 1;
  int _totalPages = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      _authorSnapshot = SocialAuthorSnapshot(
        fullName: settings.basic.fullName,
        avatarUrl: settings.basic.avatarUrl,
      );
    } catch (_) {
      _authorSnapshot = null;
    }
    await _loadComments(reset: true);
  }

  Future<void> _loadComments({required bool reset}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final pageNumber = reset ? 1 : _pageNumber + 1;
    try {
      final page = await _repo.fetchComments(widget.postId, pageNumber: pageNumber, pageSize: 20);
      setState(() {
        _comments = reset ? page.items : [..._comments, ...page.items];
        _pageNumber = page.pageNumber;
        _totalPages = page.totalPages;
      });
    } catch (_) {
      // ignore for now
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    if (_sending) return;
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;
    if (_authorSnapshot == null) return;

    setState(() => _sending = true);
    try {
      final comment = await _repo.createComment(
        postId: widget.postId,
        content: trimmed,
        authorFullName: _authorSnapshot!.fullName,
        authorAvatarUrl: _authorSnapshot!.avatarUrl,
      );

      setState(() {
        _comments = [comment, ..._comments];
        _controller.clear();
      });

      if (mounted) {
        context.read<SocialCubit>().bumpCommentCount(widget.postId);
      }
      widget.onCommentCreated?.call(widget.postId);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: const [
                    Text(
                      'Comments',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading && _comments.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? const Center(
                            child: Text(
                              'Be the first to comment.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _comments.length + (_pageNumber < _totalPages ? 1 : 0),
                            separatorBuilder: (_, _) => const Divider(height: 20),
                            itemBuilder: (context, index) {
                              if (index >= _comments.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Center(
                                    child: OutlinedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _loadComments(reset: false),
                                      child: const Text('View more'),
                                    ),
                                  ),
                                );
                              }

                              final c = _comments[index];
                              final authorName = c.authorSnapshot?.fullName ?? 'You';
                              final avatarUrl = c.authorSnapshot?.avatarUrl;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppColors.lightGreen,
                                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                        ? NetworkImage(avatarUrl)
                                        : null,
                                    child: avatarUrl == null || avatarUrl.isEmpty
                                        ? Text(
                                            authorName.isNotEmpty ? authorName[0] : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primaryGreen,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              authorName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              c.timeAgo,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          c.content,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            height: 1.4,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _sending || _authorSnapshot == null ? null : _send,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
