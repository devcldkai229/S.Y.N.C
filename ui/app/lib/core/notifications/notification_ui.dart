import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationVisual {
  const NotificationVisual({required this.icon, required this.background});

  final IconData icon;
  final Color background;
}

NotificationVisual notificationVisualFor(AppNotification notification) {
  final t = notification.type.toLowerCase();

  if (t.contains('postliked') || t.contains('storyliked')) {
    return const NotificationVisual(
      icon: Icons.favorite_rounded,
      background: Color(0xFFFCE7F3),
    );
  }
  if (t.contains('postcommented') || t.contains('commentreplied')) {
    return const NotificationVisual(
      icon: Icons.chat_bubble_rounded,
      background: Color(0xFFE0F2FE),
    );
  }
  if (t.contains('follow')) {
    return const NotificationVisual(
      icon: Icons.person_add_alt_1_rounded,
      background: AppColors.lightGreen,
    );
  }
  if (t.contains('newpost')) {
    return const NotificationVisual(
      icon: Icons.campaign_rounded,
      background: Color(0xFFFEF3C7),
    );
  }
  if (t.contains('storyviewed')) {
    return const NotificationVisual(
      icon: Icons.visibility_rounded,
      background: Color(0xFFEDE9FE),
    );
  }
  if (t.contains('challenge')) {
    return const NotificationVisual(
      icon: Icons.emoji_events_rounded,
      background: Color(0xFFFFF7ED),
    );
  }
  if (t.contains('reward') || t.contains('achievement')) {
    return const NotificationVisual(
      icon: Icons.emoji_events_outlined,
      background: AppColors.lightGreen,
    );
  }
  if (t.contains('workout') || t.contains('session')) {
    return const NotificationVisual(
      icon: Icons.fitness_center_rounded,
      background: AppColors.lightGreen,
    );
  }
  if (t.contains('ai') || t.contains('coach')) {
    return const NotificationVisual(
      icon: Icons.auto_awesome_rounded,
      background: AppColors.lightGreen,
    );
  }

  return const NotificationVisual(
    icon: Icons.notifications_rounded,
    background: AppColors.backgroundAlt,
  );
}
