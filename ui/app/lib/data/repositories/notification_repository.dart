import 'package:sync_app/data/datasources/notification_remote_data_source.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationRepository {
  NotificationRepository(this._remote);

  final NotificationRemoteDataSource _remote;

  Future<NotificationsPage> loadForUser({
    required String userId,
    int pageNumber = 1,
    int pageSize = 20,
  }) =>
      _remote.fetchNotificationsForUser(
        userId: userId,
        pageNumber: pageNumber,
        pageSize: pageSize,
      );

  Future<int> unreadCount(String userId) => _remote.fetchUnreadCount(userId);

  Future<void> markRead({required String userId, required String notificationId}) =>
      _remote.markAsRead(userId: userId, notificationId: notificationId);

  Future<void> markAllRead(String userId) => _remote.markAllAsRead(userId);
}
