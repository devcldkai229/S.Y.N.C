import 'package:flutter/foundation.dart';
import 'package:sync_app/features/social/models/social_models.dart';

/// Builds a shareable deep link / web URL for a social post.
abstract final class SocialShareLink {
  static String forPost(SocialPost post) {
    final code = post.shareCode.trim().isNotEmpty ? post.shareCode.trim() : post.id;

    if (kIsWeb) {
      final base = Uri.base;
      final path = base.path.endsWith('/') ? base.path : '${base.path}/';
      return '${base.origin}$path#/social/post/${post.id}';
    }

    return 'sync://social/share/$code';
  }
}
