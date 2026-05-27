part of 'notifications_cubit.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    required this.status,
    this.items = const [],
    this.error,
  });

  const NotificationsState.initial() : this(status: NotificationsStatus.initial);

  final NotificationsStatus status;
  final List<AppNotification> items;
  final String? error;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
