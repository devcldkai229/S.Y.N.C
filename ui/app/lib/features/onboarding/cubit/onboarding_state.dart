part of 'onboarding_cubit.dart';

class OnboardingState extends Equatable {
  const OnboardingState({
    this.currentSide = 0,
    this.sideACompleted = false,
    this.isSubmitting = false,
    this.isCompleted = false,
    this.error,
  });

  /// 0 = Side A (biometrics), 1 = Side B (preferences)
  final int currentSide;
  final bool sideACompleted;
  final bool isSubmitting;
  final bool isCompleted;
  final String? error;

  OnboardingState copyWith({
    int? currentSide,
    bool? sideACompleted,
    bool? isSubmitting,
    bool? isCompleted,
    String? error,
    bool clearError = false,
  }) {
    return OnboardingState(
      currentSide: currentSide ?? this.currentSide,
      sideACompleted: sideACompleted ?? this.sideACompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isCompleted: isCompleted ?? this.isCompleted,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [currentSide, sideACompleted, isSubmitting, isCompleted, error];
}
