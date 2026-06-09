import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/social/models/social_models.dart';

/// Bottom sheet with contextual actions for a social post.
///
/// Own post  → Delete, Hide, Copy link
/// Other's   → Hide, Copy link, Report
class SocialPostActionsSheet extends StatelessWidget {
  const SocialPostActionsSheet._({
    required this.post,
    required this.isOwnPost,
    required this.onHide,
    this.onDelete,
  });

  final SocialPost post;
  final bool isOwnPost;

  /// Required: called when the user taps "Hide". Should remove the post locally.
  final VoidCallback onHide;

  /// Optional: called when the user confirms delete. Only shown for own posts.
  final Future<void> Function()? onDelete;

  static Future<void> show(
    BuildContext context, {
    required SocialPost post,
    required bool isOwnPost,
    required VoidCallback onHide,
    Future<void> Function()? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SocialPostActionsSheet._(
        post: post,
        isOwnPost: isOwnPost,
        onHide: onHide,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Post preview header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.lightGreen,
                    child: Text(
                      post.authorSnapshot.fullName.isNotEmpty
                          ? post.authorSnapshot.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorSnapshot.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        if (post.content.isNotEmpty)
                          Text(
                            post.content.length > 60
                                ? '${post.content.substring(0, 60)}…'
                                : post.content,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 4),

            // ─── Own post ────────────────────────────────────────────────
            if (isOwnPost) ...[
              _ActionTile(
                icon: Icons.delete_outline_rounded,
                label: 'Delete post',
                color: Colors.red.shade400,
                onTap: () => _confirmDelete(context),
              ),
              _ActionTile(
                icon: Icons.visibility_off_outlined,
                label: 'Hide from my feed',
                onTap: () => _hide(context),
              ),
              _ActionTile(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: () => _copyLink(context),
              ),
            ],

            // ─── Other user's post ───────────────────────────────────────
            if (!isOwnPost) ...[
              _ActionTile(
                icon: Icons.visibility_off_outlined,
                label: 'Hide from my feed',
                onTap: () => _hide(context),
              ),
              _ActionTile(
                icon: Icons.link_rounded,
                label: 'Copy link',
                onTap: () => _copyLink(context),
              ),
              const Divider(height: 1, indent: 20, endIndent: 20),
              _ActionTile(
                icon: Icons.flag_outlined,
                label: 'Report post',
                color: Colors.orange.shade700,
                onTap: () => _report(context),
              ),
            ],

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  // ─── Handlers ─────────────────────────────────────────────────────────────

  Future<void> _confirmDelete(BuildContext context) async {
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete post', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'This will permanently remove your post. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || onDelete == null || !context.mounted) return;

    try {
      await onDelete!();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete post. Please try again.')),
        );
      }
    }
  }

  void _hide(BuildContext context) {
    Navigator.pop(context);
    onHide();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post hidden from your feed.')),
    );
  }

  void _copyLink(BuildContext context) {
    Navigator.pop(context);
    Clipboard.setData(ClipboardData(text: 'sync://social/share/${post.shareCode}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard.')),
    );
  }

  void _report(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReportSheet(post: post),
    );
  }
}

// ─── Action tile ──────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(color: effectiveColor, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      minLeadingWidth: 28,
    );
  }
}

// ─── Report sheet ─────────────────────────────────────────────────────────────

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.post});
  final SocialPost post;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  static const _reasons = [
    'Spam or misleading',
    'Inappropriate content',
    'Violence or threats',
    'Hate speech or discrimination',
    'Misinformation',
    'Other',
  ];

  int? _selected;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _submitted ? _buildSuccess(context) : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Report post',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Why are you reporting this post? Your report is anonymous.',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          ..._reasons.asMap().entries.map(
                (entry) => InkWell(
                  onTap: () => setState(() => _selected = entry.key),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selected == entry.key
                                  ? AppColors.primaryGreen
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: _selected == entry.key
                              ? Center(
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _selected != null ? _submit : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              disabledBackgroundColor: AppColors.border,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Submit report',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.lightGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, size: 40, color: AppColors.primaryGreen),
          ),
          const SizedBox(height: 20),
          const Text(
            'Thank you for your report',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "We'll review this post and take appropriate action to keep the community safe.",
            style: TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Done',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() => setState(() => _submitted = true);
}
