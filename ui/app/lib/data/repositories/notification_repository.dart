import 'package:sync_app/data/datasources/notification_remote_data_source.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationRepository {
  NotificationRepository(this._remote);

  final NotificationRemoteDataSource _remote;

  Future<NotificationsPage> loadMine({int pageNumber = 1, int pageSize = 20}) =>
      _remote.fetchMyNotifications(pageNumber: pageNumber, pageSize: pageSize);

  Future<int> unreadCount() => _remote.fetchMyUnreadCount();

  Future<void> markRead({required String notificationId}) =>
      _remote.markAsRead(notificationId);

  Future<void> markAllRead() => _remote.markAllAsRead();
}
