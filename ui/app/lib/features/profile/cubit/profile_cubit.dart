import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/profile_repository.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState.initial());

  final ProfileRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final result = await _repository.load();
      emit(state.copyWith(
        status: ProfileStatus.success,
        settings: result.settings,
        inventory: result.inventory,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
    }
  }

  Future<void> save({required String fullName, required FitnessProfile fitness}) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.save(fullName: fullName, fitness: fitness);
      emit(state.copyWith(
        status: ProfileStatus.success,
        settings: updated,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
    }
  }
}
