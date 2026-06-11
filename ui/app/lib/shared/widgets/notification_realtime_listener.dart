import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_app/core/notifications/notification_deep_link.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_realtime_service.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/notification_models.dart';

/// Starts SignalR and shows lightweight in-app toasts for social notifications.
class NotificationRealtimeListener extends StatefulWidget {
  const NotificationRealtimeListener({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationRealtimeListener> createState() => _NotificationRealtimeListenerState();
}

class _NotificationRealtimeListenerState extends State<NotificationRealtimeListener> {
  StreamSubscription<AppNotification>? _sub;

  @override
  void initState() {
    super.initState();
    getIt<NotificationRealtimeService>().start();
    _sub = getIt<NotificationInboxNotifier>().incoming.listen(_showToast);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showToast(AppNotification notification) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 4),
        content: Text(
          notification.title.isNotEmpty ? notification.title : notification.body,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        action: SnackBarAction(
          label: 'Xem',
          textColor: AppColors.brightGreen,
          onPressed: () => NotificationDeepLink.open(context, notification),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
