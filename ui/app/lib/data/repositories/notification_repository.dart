import 'package:sync_app/data/datasources/notification_remote_data_source.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationRepository {
  NotificationRepository(this._remote);

  final NotificationRemoteDataSource _remote;

  Future<List<AppNotification>> load({int pageSize = 30}) =>
      _remote.fetchNotifications(pageSize: pageSize);

  Future<void> markRead(String id) => _remote.markAsRead(id);

  Future<void> markAllRead() => _remote.markAllAsRead();
}
