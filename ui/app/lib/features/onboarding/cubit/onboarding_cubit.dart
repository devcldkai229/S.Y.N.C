import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/models/onboarding_models.dart';
import 'package:sync_app/data/repositories/onboarding_repository.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingState());

  final OnboardingRepository _repository;

  void updateStep(int step) => emit(state.copyWith(currentStep: step));

  Future<bool> submitStep1(OnboardingStep1Request request) => _submit(
        () => _repository.submitStep1(request),
        nextStep: 1,
      );

  Future<bool> submitStep2(OnboardingStep2Request request) => _submit(
        () => _repository.submitStep2(request),
        nextStep: 2,
      );

  Future<bool> submitStep3(OnboardingStep3Request request) => _submit(
        () => _repository.submitStep3(request),
        nextStep: 3,
      );

  Future<bool> submitStep4(OnboardingStep4Request request) => _submit(
        () => _repository.submitStep4(request),
        nextStep: 4,
        completed: true,
      );

  Future<bool> _submit(
    Future<void> Function() action, {
    required int nextStep,
    bool completed = false,
  }) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await action();
      emit(state.copyWith(
        isSubmitting: false,
        currentStep: nextStep,
        isCompleted: completed,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, error: mapApiError(e)));
      return false;
    }
  }
}
