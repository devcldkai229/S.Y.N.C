import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_realtime_service.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor = AppColors.textPrimary,
    this.iconSize = 26,
  });

  final Color iconColor;
  final double iconSize;

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton> {
  NotificationInboxNotifier get _inbox => getIt<NotificationInboxNotifier>();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _inbox.addListener(_onInboxChanged);
    _loadUnreadCount();
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => _loadUnreadCount());
    getIt<NotificationRealtimeService>().start();
  }

  @override
  void dispose() {
    _inbox.removeListener(_onInboxChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onInboxChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await getIt<NotificationRepository>().unreadCount();
      _inbox.setUnreadCount(count);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 404 || status == 502 || status == 503) {
        _inbox.setUnreadCount(0);
      }
    } catch (_) {
      // Badge is best-effort
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _inbox.unreadCount;

    return IconButton(
      onPressed: () async {
        await context.push(AppRoutes.notifications);
        if (mounted) await _loadUnreadCount();
      },
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10),
        ),
        child: Icon(
          Icons.notifications_none_rounded,
          color: widget.iconColor,
          size: widget.iconSize,
        ),
      ),
    );
  }
}
