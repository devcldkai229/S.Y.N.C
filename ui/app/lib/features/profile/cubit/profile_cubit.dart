import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/safe_emit.dart';
import 'package:sync_app/data/repositories/profile_repository.dart';
import 'package:sync_app/features/profile/models/profile_models.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> with SafeEmitMixin<ProfileState> {
  ProfileCubit(this._repository) : super(const ProfileState.initial());

  final ProfileRepository _repository;

  Future<void> load() async {
    safeEmit(state.copyWith(status: ProfileStatus.loading, clearError: true));
    try {
      final result = await _repository.load();
      safeEmit(state.copyWith(
        status: ProfileStatus.success,
        settings: result.settings,
        inventory: result.inventory,
        biometric: result.biometric,
        publicProfile: result.publicProfile,
      ));
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
    }
  }

  Future<bool> saveBasic({
    required String fullName,
    String? avatarUrl,
    String? backgroundImageUrl,
    String? preferredLanguage,
    String? timeZone,
  }) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updateBasic(
        fullName: fullName,
        avatarUrl: avatarUrl,
        backgroundImageUrl: backgroundImageUrl,
        preferredLanguage: preferredLanguage,
        timeZone: timeZone,
      );
      safeEmit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> uploadAndSaveAvatar(XFile file) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final urls = await _repository.uploadProfileMedia(file);
      if (urls.isEmpty) throw Exception('Upload failed');
      final updated = await _repository.updateBasic(avatarUrl: urls.first);
      safeEmit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> uploadAndSaveBackground(XFile file) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final urls = await _repository.uploadProfileMedia(file);
      if (urls.isEmpty) throw Exception('Upload failed');
      final updated = await _repository.updateBasic(backgroundImageUrl: urls.first);
      safeEmit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> saveFitness(FitnessProfile fitness) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updateFitness(fitness);
      BiometricProfileDetail? biometric;
      try {
        biometric = (await _repository.load()).biometric;
      } catch (_) {}
      safeEmit(state.copyWith(
        status: ProfileStatus.success,
        settings: updated,
        biometric: biometric,
      ));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> savePreferences(AccountPreferences preferences) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      final updated = await _repository.updatePreferences(preferences);
      safeEmit(state.copyWith(status: ProfileStatus.success, settings: updated));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> logWeight(double kg) async {
    safeEmit(state.copyWith(status: ProfileStatus.saving, clearError: true));
    try {
      await _repository.logWeight(kg);
      final result = await _repository.load();
      safeEmit(state.copyWith(
        status: ProfileStatus.success,
        settings: result.settings,
        inventory: result.inventory,
        biometric: result.biometric,
        publicProfile: result.publicProfile,
      ));
      return true;
    } catch (e) {
      safeEmit(state.copyWith(status: ProfileStatus.failure, error: mapApiError(e)));
      return false;
    }
  }
}
