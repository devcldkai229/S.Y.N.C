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
        biometric: result.biometric,
        publicProfile: result.publicProfile,
      ));
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
    }
  }

  Future<bool> saveBasic({
    required String fullName,
    String? preferredLanguage,
    String? timeZone,
  }) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updateBasic(
        fullName: fullName,
        preferredLanguage: preferredLanguage,
        timeZone: timeZone,
      );
      emit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> saveFitness(FitnessProfile fitness) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updateFitness(fitness);
      BiometricProfileDetail? biometric;
      try {
        biometric = (await _repository.load()).biometric;
      } catch (_) {}
      emit(state.copyWith(
        status: ProfileStatus.success,
        settings: updated,
        biometric: biometric,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> savePreferences(AccountPreferences preferences) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updatePreferences(preferences);
      emit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> logWeight(double kg) async {
    emit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      await _repository.logWeight(kg);
      final result = await _repository.load();
      emit(state.copyWith(
        status: ProfileStatus.success,
        settings: result.settings,
        inventory: result.inventory,
        biometric: result.biometric,
        publicProfile: result.publicProfile,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }
}
