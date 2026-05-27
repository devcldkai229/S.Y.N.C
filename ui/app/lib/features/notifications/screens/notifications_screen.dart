import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
          title: const Text('Notifications'),
        ),
        body: BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) {
            if (state.status == NotificationsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            }
            if (state.status == NotificationsStatus.failure) {
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
                child: Text('No notifications yet.', style: TextStyle(color: AppColors.textMuted)),
              );
            }

            final groups = _groupByDay(state.items);
            return RefreshIndicator(
              color: AppColors.primaryGreen,
              onRefresh: () => context.read<NotificationsCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  for (final entry in groups.entries) ...[
                    _SectionHeader(title: entry.key),
                    const SizedBox(height: 8),
                    ...entry.value.map(_notificationTile),
                    const SizedBox(height: 16),
                  ],
                ],
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

  Widget _notificationTile(AppNotification n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NotificationCard(
        accentBar: !n.isRead,
        icon: _iconForType(n.type),
        iconBackground: AppColors.lightGreen,
        title: n.title,
        time: n.timeAgoLabel,
        body: n.body,
      ),
    );
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('reward') || t.contains('achievement')) return Icons.emoji_events_outlined;
    if (t.contains('session') || t.contains('workout')) return Icons.timer_outlined;
    if (t.contains('ai') || t.contains('coach')) return Icons.smart_toy_outlined;
    return Icons.notifications_outlined;
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
