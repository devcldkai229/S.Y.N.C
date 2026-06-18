import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/notifications/notification_deep_link.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_ui.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/features/notifications/cubit/notifications_cubit.dart';
import 'package:sync_app/shared/widgets/notification_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit(getIt())..load(),
      child: Scaffold(
        backgroundColor: AppColors.backgroundAlt,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.pop(),
          ),
          title: const Text('Thông báo'),
          actions: [
            BlocBuilder<NotificationsCubit, NotificationsState>(
              buildWhen: (prev, next) => prev.unreadCount != next.unreadCount,
              builder: (context, state) {
                if (state.unreadCount == 0) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () => context.read<NotificationsCubit>().markAllAsRead(),
                  child: const Text('Đọc tất cả'),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }
            if (state.status == NotificationsStatus.failure && state.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.error ?? 'Failed to load'),
                    TextButton(
                      onPressed: () => context.read<NotificationsCubit>().load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state.items.isEmpty) {
              return const Center(
                child: Text(
                  'Không có thông báo',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              );
            }

            final groups = _groupByDay(state.items);
            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<NotificationsCubit>().load(),
              child: NotificationListener<ScrollNotification>(
                onNotification: (scroll) {
                  const thresholdPx = 200.0;
                  if (scroll.metrics.extentAfter < thresholdPx) {
                    context.read<NotificationsCubit>().loadMore();
                  }
                  return false;
                },
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (state.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '${state.unreadCount} chưa đọc',
                          style: const TextStyle(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    for (final entry in groups.entries) ...[
                      _SectionHeader(title: entry.key),
                      const SizedBox(height: 8),
                      ...entry.value.map((n) => _notificationTile(context, n)),
                      const SizedBox(height: 16),
                    ],
                    if (state.isLoadingMore) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ] else if (state.hasMore) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: OutlinedButton(
                            onPressed: () => context.read<NotificationsCubit>().loadMore(),
                            child: const Text('View more'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, List<AppNotification>> _groupByDay(List<AppNotification> items) {
    final sorted = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final map = <String, List<AppNotification>>{};
    final now = DateTime.now();
    for (final n in sorted) {
      final label = _dayLabel(n.createdAt, now);
      map.putIfAbsent(label, () => []).add(n);
    }
    return map;
  }

  String _dayLabel(DateTime date, DateTime now) {
    final d = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return 'LAST WEEK';
    return '${date.month}/${date.day}/${date.year}';
  }

  Widget _notificationTile(BuildContext context, AppNotification n) {
    final visual = notificationVisualFor(n);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (!n.isRead) {
              await context.read<NotificationsCubit>().markAsRead(n.id);
              getIt<NotificationInboxNotifier>().decrementUnread();
            }
            if (context.mounted) NotificationDeepLink.open(context, n);
          },
          child: NotificationCard(
            accentBar: !n.isRead,
            icon: visual.icon,
            iconBackground: visual.background,
            title: n.title,
            time: n.timeAgoLabel,
            body: n.body,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: AppColors.textMuted,
      ),
    );
  }
}
