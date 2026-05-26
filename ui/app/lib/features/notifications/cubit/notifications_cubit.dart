import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/models/notification_models.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState.initial());

  final NotificationRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: NotificationsStatus.loading, clearError: true));
    try {
      final items = await _repository.load();
      emit(state.copyWith(status: NotificationsStatus.success, items: items));
    } catch (e) {
      emit(state.copyWith(status: NotificationsStatus.failure, error: mapApiError(e)));
    }
  }
}
