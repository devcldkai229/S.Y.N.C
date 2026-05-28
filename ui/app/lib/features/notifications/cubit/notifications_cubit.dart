import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, this._profileApi) : super(const NotificationsState.initial());

  final NotificationRepository _repository;
  final ProfileApiService _profileApi;

  static const _pageSize = 20;
  String? _userId;

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
      final settings = await _profileApi.getProfileSettings();
      final userId = settings.userId;
      if (userId.isEmpty) {
        emit(state.copyWith(status: NotificationsStatus.failure, error: 'User profile not available.'));
        return;
      }
      _userId = userId;

      final results = await Future.wait([
        _repository.loadForUser(userId: userId, pageNumber: 1, pageSize: _pageSize),
        _repository.unreadCount(userId),
      ]);
      final page = results[0] as NotificationsPage;
      final unread = results[1] as int;

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
      emit(state.copyWith(status: NotificationsStatus.failure, error: mapApiError(e)));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final userId = _userId;
    if (userId == null) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final nextPage = state.pageNumber + 1;
      final page = await _repository.loadForUser(
        userId: userId,
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
      emit(state.copyWith(isLoadingMore: false, error: mapApiError(e)));
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final userId = _userId;
    if (userId == null) return;

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
      await _repository.markRead(userId: userId, notificationId: notificationId);
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
    final userId = _userId;
    if (userId == null || state.unreadCount == 0) return;

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

    try {
      await _repository.markAllRead(userId);
    } catch (e) {
      emit(state.copyWith(items: previous, error: mapApiError(e)));
      await load();
    }
  }
}
