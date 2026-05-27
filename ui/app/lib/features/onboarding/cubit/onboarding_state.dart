part of 'onboarding_cubit.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentStep = 0,
    this.isSubmitting = false,
    this.isCompleted = false,
    this.error,
  });

  final int currentStep;
  final bool isSubmitting;
  final bool isCompleted;
  final String? error;

  OnboardingState copyWith({
    int? currentStep,
    bool? isSubmitting,
    bool? isCompleted,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [currentStep, isSubmitting, isCompleted, error];
}
