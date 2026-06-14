import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState.initial());

  final NotificationRepository _repository;

  static const _pageSize = 20;

  Future<void> load() async {
    emit(
      state.copyWith(
        status: NotificationsStatus.loading,
        clearError: true,
        items: const [],
        pageNumber: 1,
        totalPages: 1,
        hasMore: false,
        isLoadingMore: false,
      ),
    );
    try {
      final page = await _repository.loadMine(pageNumber: 1, pageSize: _pageSize);
      final unread = await _loadUnreadCountBestEffort(page);

      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          items: page.items,
          pageNumber: page.pagination.pageNumber,
          totalPages: page.pagination.totalPages,
          hasMore: page.pagination.pageNumber < page.pagination.totalPages,
          isLoadingMore: false,
          unreadCount: unread,
        ),
      );
    } catch (e) {
      if (_isEmptyOrUnavailable(e)) {
        emit(
          state.copyWith(
            status: NotificationsStatus.success,
            items: const [],
            unreadCount: 0,
            clearError: true,
          ),
        );
        return;
      }
      emit(state.copyWith(status: NotificationsStatus.failure, error: mapNotificationError(e)));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.pageNumber + 1;
      final page = await _repository.loadMine(
        pageNumber: nextPage,
        pageSize: _pageSize,
      );

      final merged = [...state.items, ...page.items];
      emit(
        state.copyWith(
          status: NotificationsStatus.success,
          items: merged,
          pageNumber: page.pagination.pageNumber,
          totalPages: page.pagination.totalPages,
          hasMore: page.pagination.pageNumber < page.pagination.totalPages,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false, error: mapNotificationError(e)));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final idx = state.items.indexWhere((n) => n.id == notificationId);
    if (idx < 0) return;
    final item = state.items[idx];
    if (item.isRead) return;

    final optimistic = item.copyWith(
      readAt: DateTime.now(),
      status: 'Read',
    );
    final updated = [...state.items];
    updated[idx] = optimistic;
    emit(
      state.copyWith(
        items: updated,
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      ),
    );

    try {
      await _repository.markRead(notificationId: notificationId);
    } catch (_) {
      final rollback = [...state.items];
      rollback[idx] = item;
      emit(
        state.copyWith(
          items: rollback,
          unreadCount: state.unreadCount + 1,
        ),
      );
    }
  }

  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;

    final previous = state.items;
    final now = DateTime.now();
    emit(
      state.copyWith(
        items: previous
            .map((n) => n.isRead ? n : n.copyWith(readAt: now, status: 'Read'))
            .toList(),
        unreadCount: 0,
      ),
    );

    getIt<NotificationInboxNotifier>().clearUnread();

    try {
      await _repository.markAllRead();
    } catch (e) {
      emit(state.copyWith(items: previous, error: mapNotificationError(e)));
      await load();
    }
  }

  Future<int> _loadUnreadCountBestEffort(NotificationsPage page) async {
    try {
      final unread = await _repository.unreadCount();
      getIt<NotificationInboxNotifier>().setUnreadCount(unread);
      return unread;
    } catch (_) {
      final fallback = getIt<NotificationInboxNotifier>().unreadCount;
      if (fallback > 0) return fallback;
      return page.items.where((n) => !n.isRead).length;
    }
  }

  bool _isEmptyOrUnavailable(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 404 || status == 502 || status == 503) return true;
      if (error.type == DioExceptionType.connectionError) return true;
    }
    return false;
  }
}

String mapNotificationError(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 404 || status == 502 || status == 503) {
      return 'Không có thông báo';
    }
    if (status == 401) {
      return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
    }
    if (error.type == DioExceptionType.connectionError) {
      return 'Không kết nối được dịch vụ thông báo. Hãy chạy backend (run-all.ps1).';
    }
  }
  return mapApiError(error);
}
