import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/models/onboarding_models.dart';
import 'package:sync_app/data/repositories/onboarding_repository.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingState());

  final OnboardingRepository _repository;

  Future<bool> submitSideA({
    required OnboardingStep1Request basic,
    required OnboardingStep2Request goals,
    required OnboardingStep4Request safeguards,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.submitStep1(basic);
      await _repository.submitStep2(goals);
      await _repository.submitStep4(safeguards);
      emit(state.copyWith(
        isSubmitting: false,
        sideACompleted: true,
        currentSide: 1,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: mapApiError(e)));
      return false;
    }
  }

  Future<bool> submitSideB(OnboardingAccountPreferencesRequest preferences) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _repository.submitAccountPreferences(preferences);
      await _repository.completeOnboarding();
      emit(state.copyWith(isSubmitting: false, isCompleted: true));
      return true;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: mapApiError(e)));
      return false;
    }
  }
}
