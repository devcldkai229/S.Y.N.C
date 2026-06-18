import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/data/repositories/home_repository.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._repository) : super(const HomeState.initial());

  final HomeRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));
    try {
      final data = await _repository.loadDashboard();
      emit(state.copyWith(status: HomeStatus.success, data: data));
    } catch (e) {
      emit(state.copyWith(status: HomeStatus.failure, error: mapApiError(e)));
    }
  }
}
