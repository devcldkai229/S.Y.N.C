import 'package:sync_app/features/social/models/social_models.dart';

/// A parent comment with all nested replies grouped underneath (Facebook-style).
class CommentThread {
  const CommentThread({
    required this.parent,
    required this.replies,
  });

  final SocialComment parent;
  final List<SocialComment> replies;
}

/// Groups a flat comment list into parent → replies threads.
abstract final class CommentThreadUtils {
  static const initialVisibleReplies = 2;

  static List<CommentThread> groupComments(List<SocialComment> flat) {
    if (flat.isEmpty) return const [];

    final byId = {for (final c in flat) c.id: c};

    final parents = flat
        .where((c) => c.parentCommentId == null || c.parentCommentId!.isEmpty)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final replies = flat
        .where((c) => c.parentCommentId != null && c.parentCommentId!.isNotEmpty)
        .toList();

    final repliesByRoot = <String, List<SocialComment>>{};

    for (final reply in replies) {
      final rootId = _rootParentId(reply, byId);
      repliesByRoot.putIfAbsent(rootId, () => []).add(reply);
    }

    for (final list in repliesByRoot.values) {
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return parents
        .map(
          (parent) => CommentThread(
            parent: parent,
            replies: repliesByRoot[parent.id] ?? const [],
          ),
        )
        .toList();
  }

  /// Walks up the parent chain so nested replies still appear under the root comment.
  static String _rootParentId(SocialComment comment, Map<String, SocialComment> byId) {
    var current = comment;
    var guard = 0;

    while (current.parentCommentId != null &&
        current.parentCommentId!.isNotEmpty &&
        guard < 32) {
      guard++;
      final parent = byId[current.parentCommentId!];
      if (parent == null) return current.parentCommentId!;
      if (parent.parentCommentId == null || parent.parentCommentId!.isEmpty) {
        return parent.id;
      }
      current = parent;
    }

    return comment.parentCommentId ?? comment.id;
  }
}
