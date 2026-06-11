import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/utils/comment_thread_utils.dart';
import 'package:sync_app/features/social/widgets/social_comment_thread_widgets.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

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
  final _inputFocus = FocusNode();

  bool _sending = false;

  final _repo = getIt<SocialRepository>();
  final _profileApi = getIt<ProfileApiService>();

  SocialAuthorSnapshot? _authorSnapshot;
  List<SocialComment> _comments = const [];
  int _pageNumber = 1;
  int _totalPages = 1;
  bool _isLoading = false;

  String? _replyToCommentId;
  String? _replyToUsername;

  List<CommentThread> get _threads => CommentThreadUtils.groupComments(_comments);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      _authorSnapshot = SocialAuthorSnapshot(
        fullName: settings.basic.fullName.isNotEmpty ? settings.basic.fullName : 'You',
        avatarUrl: settings.basic.avatarUrl,
      );
    } catch (_) {
      _authorSnapshot = const SocialAuthorSnapshot(fullName: 'You');
    }
    await _loadComments(reset: true);
  }

  Future<void> _loadComments({required bool reset}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final pageNumber = reset ? 1 : _pageNumber + 1;
    try {
      final page = await _repo.fetchComments(widget.postId, pageNumber: pageNumber, pageSize: 50);
      setState(() {
        _comments = reset ? page.items : [..._comments, ...page.items];
        _pageNumber = page.pageNumber;
        _totalPages = page.totalPages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startReply(SocialComment comment) {
    final username = comment.authorSnapshot?.fullName ?? 'người dùng';
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUsername = username;
      _controller.clear();
    });
    _inputFocus.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToCommentId = null;
      _replyToUsername = null;
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final trimmed = _controller.text.trim();
    if (trimmed.isEmpty) return;

    setState(() => _sending = true);
    final isReply = _replyToCommentId != null;
    try {
      final authorName = _authorSnapshot?.fullName;
      final authorAvatar = _authorSnapshot?.avatarUrl;

      if (isReply) {
        await _repo.createReply(
          commentId: _replyToCommentId!,
          content: trimmed,
          parentCommentId: _replyToCommentId!,
          authorFullName: authorName,
          authorAvatarUrl: authorAvatar,
        );
      } else {
        await _repo.createComment(
          postId: widget.postId,
          content: trimmed,
          authorFullName: authorName,
          authorAvatarUrl: authorAvatar,
        );
      }

      setState(() {
        _controller.clear();
        _replyToCommentId = null;
        _replyToUsername = null;
      });

      if (mounted) {
        context.read<SocialCubit>().bumpCommentCount(widget.postId);
      }
      widget.onCommentCreated?.call(widget.postId);
      await _loadComments(reset: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isReply ? 'Đã gửi trả lời.' : 'Đã gửi bình luận.'),
            backgroundColor: AppColors.primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final composerAuthor = _authorSnapshot?.fullName ?? 'You';

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, sheetScrollController) {
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
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Bình luận',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _buildCommentList(sheetScrollController),
              ),
              if (_replyToUsername != null)
                SocialReplyingBanner(
                  username: _replyToUsername!,
                  onCancel: _cancelReply,
                ),
              _CommentComposer(
                authorName: composerAuthor,
                avatarUrl: _authorSnapshot?.avatarUrl,
                controller: _controller,
                focusNode: _inputFocus,
                sending: _sending,
                hintText: _replyToUsername != null
                    ? 'Viết trả lời...'
                    : 'Viết bình luận...',
                onSend: _send,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentList(ScrollController sheetScrollController) {
    if (_isLoading && _comments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_threads.isEmpty) {
      return const Center(
        child: Text(
          'Hãy là người bình luận đầu tiên.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.builder(
      controller: sheetScrollController,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      itemCount: _threads.length + (_pageNumber < _totalPages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _threads.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => _loadComments(reset: false),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Xem thêm bình luận'),
              ),
            ),
          );
        }

        final thread = _threads[index];
        return SocialCommentThreadTile(
          thread: thread,
          onReply: _startReply,
        );
      },
    );
  }
}

class _CommentComposer extends StatelessWidget {
  const _CommentComposer({
    required this.authorName,
    required this.avatarUrl,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.hintText,
    required this.onSend,
  });

  final String authorName;
  final String? avatarUrl;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final String hintText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.8))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SyncAvatar(name: authorName, imageUrl: avatarUrl, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  fillColor: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                minimumSize: const Size(40, 40),
              ),
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
