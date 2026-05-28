part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    required this.status,
    this.items = const [],
    this.error,
    this.pageNumber = 1,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.unreadCount = 0,
  });

  const NotificationsState.initial() : this(status: NotificationsStatus.initial);

  final NotificationsStatus status;
  final List<AppNotification> items;
  final String? error;
  final int pageNumber;
  final int totalPages;
  final bool isLoadingMore;
  final bool hasMore;
  final int unreadCount;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    String? error,
    bool clearError = false,
    int? pageNumber,
    int? totalPages,
    bool? isLoadingMore,
    bool? hasMore,
    int? unreadCount,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, error, pageNumber, totalPages, isLoadingMore, hasMore, unreadCount];
}
