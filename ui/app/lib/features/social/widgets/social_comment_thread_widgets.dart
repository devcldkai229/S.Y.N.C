import 'package:flutter/material.dart';
import 'package:sync_app/features/social/models/social_models.dart';
import 'package:sync_app/features/social/utils/comment_thread_utils.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

/// Facebook-style comment thread: parent bubble + indented replies with connectors.
class SocialCommentThreadTile extends StatefulWidget {
  const SocialCommentThreadTile({
    super.key,
    required this.thread,
    required this.onReply,
  });

  final CommentThread thread;
  final void Function(SocialComment comment) onReply;

  @override
  State<SocialCommentThreadTile> createState() => _SocialCommentThreadTileState();
}

class _SocialCommentThreadTileState extends State<SocialCommentThreadTile> {
  bool _showAllReplies = false;

  @override
  Widget build(BuildContext context) {
    final replies = widget.thread.replies;
    final showViewAll = !_showAllReplies &&
        replies.length > CommentThreadUtils.initialVisibleReplies;
    final visibleReplies = _showAllReplies
        ? replies
        : replies.take(CommentThreadUtils.initialVisibleReplies).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentRow(
            comment: widget.thread.parent,
            isReply: false,
            showConnector: false,
            onReply: () => widget.onReply(widget.thread.parent),
          ),
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 4),
            if (showViewAll)
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _showAllReplies = true),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Xem tất cả ${replies.length} phản hồi',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _CommentTheme.muted(context),
                    ),
                  ),
                ),
              ),
            ...visibleReplies.asMap().entries.map((entry) {
              final index = entry.key;
              final reply = entry.value;
              final isLast = index == visibleReplies.length - 1;
              return _CommentRow(
                comment: reply,
                isReply: true,
                showConnector: true,
                isLastInGroup: isLast,
                onReply: () => widget.onReply(reply),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _CommentRow extends StatelessWidget {
  const _CommentRow({
    required this.comment,
    required this.isReply,
    required this.showConnector,
    required this.onReply,
    this.isLastInGroup = true,
  });

  final SocialComment comment;
  final bool isReply;
  final bool showConnector;
  final bool isLastInGroup;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final authorName = comment.authorSnapshot?.fullName ?? 'Người dùng';
    final avatarUrl = comment.authorSnapshot?.avatarUrl;
    final avatarRadius = isReply ? 12.0 : 16.0;

    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SyncAvatar(
          name: authorName,
          imageUrl: avatarUrl,
          radius: avatarRadius,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CommentBubble(
                authorName: authorName,
                content: comment.content,
              ),
              const SizedBox(height: 2),
              _CommentActionRow(
                timeAgo: comment.timeAgo,
                onReply: onReply,
              ),
            ],
          ),
        ),
      ],
    );

    if (!showConnector) return content;

    return Padding(
      padding: const EdgeInsets.only(left: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              child: _ReplyConnectorLine(isLast: isLastInGroup),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

/// Curved L-shaped connector from parent avatar column down to reply.
class _ReplyConnectorLine extends StatelessWidget {
  const _ReplyConnectorLine({required this.isLast});

  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final lineColor = _CommentTheme.connector(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: lineColor, width: 2),
            bottom: BorderSide(color: lineColor, width: 2),
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.authorName,
    required this.content,
  });

  final String authorName;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _CommentTheme.bubble(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: _CommentTheme.primaryText(context),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: _CommentTheme.primaryText(context),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentActionRow extends StatelessWidget {
  const _CommentActionRow({
    required this.timeAgo,
    required this.onReply,
  });

  final String timeAgo;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final muted = _CommentTheme.muted(context);

    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 2),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          Text(
            timeAgo,
            style: TextStyle(fontSize: 12, color: muted),
          ),
          Text('·', style: TextStyle(fontSize: 12, color: muted)),
          GestureDetector(
            onTap: onReply,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Trả lời',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner shown above the composer when replying to a comment.
class SocialReplyingBanner extends StatelessWidget {
  const SocialReplyingBanner({
    super.key,
    required this.username,
    required this.onCancel,
  });

  final String username;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Đang trả lời $username...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _CommentTheme.muted(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(Icons.close, size: 18, color: _CommentTheme.muted(context)),
          ),
        ],
      ),
    );
  }
}

abstract final class _CommentTheme {
  static Color bubble(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF3A3B3C) : Colors.grey.shade200;
  }

  static Color primaryText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color muted(BuildContext context) {
    return Colors.grey.shade600;
  }

  static Color connector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.grey.shade600 : Colors.grey.shade400;
  }
}
