import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/data/models/notification_models.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AppNotification>> fetchNotifications({
    int pageNumber = 1,
    int pageSize = 30,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.notifications,
      queryParameters: {'pageNumber': pageNumber, 'pageSize': pageSize},
    );
    final raw = response.data?['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>('${ApiPaths.notifications}/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.patch<void>('${ApiPaths.notifications}/read-all');
  }
}
