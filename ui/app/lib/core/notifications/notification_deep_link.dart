import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/data/models/notification_models.dart';

/// Navigates from notification [deepLink] / payload to in-app routes.
abstract final class NotificationDeepLink {
  static void open(BuildContext context, AppNotification notification) {
    final link = (notification.deepLink ?? '').trim();
    if (link.isEmpty) {
      _openFromPayload(context, notification);
      return;
    }

    final normalized = link.startsWith('/') ? link : '/$link';

    if (normalized.startsWith('/social/user/')) {
      final userId = normalized.split('/').last;
      if (userId.isNotEmpty) {
        context.push(AppRoutes.socialUserProfile(userId));
        return;
      }
    }

    if (normalized.startsWith('/social/post/')) {
      context.go(AppRoutes.social);
      return;
    }

    if (normalized.startsWith('/social/story/')) {
      context.go(AppRoutes.social);
      return;
    }

    if (normalized.startsWith('/challenges/')) {
      final id = normalized.split('/').last;
      if (id.isNotEmpty) {
        context.push(AppRoutes.challengeDetail(id));
        return;
      }
    }

    if (normalized.startsWith('/orders/')) {
      final id = normalized.split('/').last;
      if (id.isNotEmpty) {
        context.push(AppRoutes.orderDetail(id));
        return;
      }
    }

    _openFromPayload(context, notification);
  }

  static void _openFromPayload(BuildContext context, AppNotification notification) {
    final challengeId = notification.challengeId;
    if (challengeId != null && challengeId.isNotEmpty) {
      context.push(AppRoutes.challengeDetail(challengeId));
      return;
    }

    final actorId = notification.actorId;
    if (actorId != null && actorId.isNotEmpty) {
      context.push(AppRoutes.socialUserProfile(actorId));
      return;
    }

    final postId = notification.postId;
    if (postId != null && postId.isNotEmpty) {
      context.go(AppRoutes.social);
    }
  }
}
