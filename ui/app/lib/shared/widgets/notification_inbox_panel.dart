import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/notifications/notification_deep_link.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_ui.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/features/notifications/cubit/notifications_cubit.dart';
import 'package:sync_app/shared/widgets/notification_card.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

/// Cursor-style notification dropdown anchored to the bell icon.
class NotificationInboxPanel {
  NotificationInboxPanel._();

  static Future<void> show(BuildContext context, {required Rect anchor}) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Thông báo',
      barrierColor: Colors.black.withValues(alpha: 0.18),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, _) {
        return BlocProvider(
          create: (_) => NotificationsCubit(getIt())..load(),
          child: _NotificationInboxPanelBody(anchor: anchor),
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
            alignment: Alignment.topRight,
            child: child,
          ),
        );
      },
    );
  }
}

class _NotificationInboxPanelBody extends StatelessWidget {
  const _NotificationInboxPanelBody({required this.anchor});

  final Rect anchor;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    const panelWidth = 400.0;
    const gap = 8.0;
    final width = math.min(panelWidth, screen.width - 24);
    final right = math.max(12.0, screen.width - anchor.right);
    final top = anchor.bottom + gap;
    final maxHeight = math.min(520.0, screen.height - top - padding.bottom - 16);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: top,
            right: right,
            width: width,
            child: Container(
              constraints: BoxConstraints(maxHeight: maxHeight),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderLight),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PanelHeader(
                    onViewAll: () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.notifications);
                    },
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: BlocBuilder<NotificationsCubit, NotificationsState>(
                      builder: (context, state) => _PanelList(state: state),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Thông báo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (prev, next) => prev.unreadCount != next.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationsCubit>().markAllAsRead(),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('Đọc tất cả'),
              );
            },
          ),
          IconButton(
            tooltip: 'Xem tất cả',
            onPressed: onViewAll,
            icon: const Icon(Icons.open_in_new_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PanelList extends StatelessWidget {
  const _PanelList({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == NotificationsStatus.loading) {
      return const _NotificationSkeletonList();
    }

    if (state.status == NotificationsStatus.failure && state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.error ?? 'Không tải được thông báo',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.read<NotificationsCubit>().load(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.textMuted),
            SizedBox(height: 12),
            Text(
              'Chưa có thông báo',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scroll) {
        if (scroll.metrics.extentAfter < 120) {
          context.read<NotificationsCubit>().loadMore();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        shrinkWrap: true,
        itemCount: state.items.length + (state.isLoadingMore ? 2 : (state.hasMore ? 1 : 0)),
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: SyncShimmerBox(height: 72, borderRadius: 16),
            );
          }

          final n = state.items[index];
          return _PanelNotificationTile(notification: n);
        },
      ),
    );
  }
}

class _PanelNotificationTile extends StatelessWidget {
  const _PanelNotificationTile({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final visual = notificationVisualFor(notification);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (!notification.isRead) {
            await context.read<NotificationsCubit>().markAsRead(notification.id);
            getIt<NotificationInboxNotifier>().decrementUnread();
          }
          if (!context.mounted) return;
          Navigator.of(context).pop();
          NotificationDeepLink.open(context, notification);
        },
        child: NotificationCard(
          accentBar: !notification.isRead,
          icon: visual.icon,
          iconBackground: visual.background,
          title: notification.title,
          time: notification.timeAgoLabel,
          body: notification.body,
        ),
      ),
    );
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, _) => const _NotificationSkeletonRow(),
    );
  }
}

class _NotificationSkeletonRow extends StatelessWidget {
  const _NotificationSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SyncShimmerBox(height: 44, width: 44, borderRadius: 22),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SyncShimmerBox(height: 14, width: 180),
              SizedBox(height: 8),
              SyncShimmerBox(height: 12),
              SizedBox(height: 6),
              SyncShimmerBox(height: 12, width: 220),
            ],
          ),
        ),
      ],
    );
  }
}
