import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<NotificationsPage> fetchNotificationsForUser({
    required String userId,
    int pageNumber = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.notificationUserInbox(userId),
      queryParameters: <String, dynamic>{
        'pageNumber': pageNumber,
        'pageSize': pageSize,
      },
    );

    final envelope = PagedApiEnvelope<List<AppNotification>>.fromJson(
      response.data ?? {},
      (dynamic rawData) {
        if (rawData is! List) return <AppNotification>[];
        return rawData
            .whereType<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList();
      },
    );

    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'Failed to load notifications.');
    }

    return NotificationsPage(
      items: envelope.data!,
      pagination: envelope.pagination,
    );
  }

  Future<int> fetchUnreadCount(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.notificationUnreadCount(userId),
    );
    final envelope = ApiEnvelope<int>.fromJson(
      response.data ?? {},
      (dynamic raw) => raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0,
    );
    if (!envelope.success || envelope.data == null) {
      throw Exception(envelope.message.isNotEmpty ? envelope.message : 'Failed to load unread count.');
    }
    return envelope.data!;
  }

  Future<void> markAsRead({required String userId, required String notificationId}) async {
    await _dio.patch<void>(ApiPaths.notificationMarkRead(userId, notificationId));
  }

  Future<void> markAllAsRead(String userId) async {
    await _dio.post<void>(ApiPaths.notificationMarkAllRead(userId));
  }
}
