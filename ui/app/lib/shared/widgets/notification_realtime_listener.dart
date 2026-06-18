import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sync_app/core/notifications/notification_deep_link.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_realtime_service.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/features/nutrition/services/nutrition_realtime_service.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/shared/widgets/sync_snack_bar.dart';

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
    getIt<NutritionRealtimeService>().start();
    _sub = getIt<NotificationInboxNotifier>().incoming.listen(_showToast);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _showToast(AppNotification notification) {
    if (!mounted) return;
    final type = notification.type.toLowerCase();
    if (type.contains('meal') || type.contains('order')) {
      getIt<ActiveOrderCountNotifier>().refresh();
    }

    showSyncSnackBar(
      context,
      backgroundColor: AppColors.textPrimary,
      message: notification.title.isNotEmpty ? notification.title : notification.body,
      action: SnackBarAction(
        label: 'Xem',
        textColor: AppColors.brightGreen,
        onPressed: () => NotificationDeepLink.open(context, notification),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
