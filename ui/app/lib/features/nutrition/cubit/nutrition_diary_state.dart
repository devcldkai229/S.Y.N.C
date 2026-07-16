part of 'nutrition_diary_cubit.dart';

enum NutritionDiaryStatus { initial, loading, loaded, error }

class NutritionDiaryState extends Equatable {
  const NutritionDiaryState({
    this.status = NutritionDiaryStatus.initial,
    required this.selectedDate,
    this.summary,
    this.mealLogs = const [],
    this.errorMessage,
    this.fitnessGoal,
  });

  final NutritionDiaryStatus status;
  final DateTime selectedDate;
  final DailyNutritionSummary? summary;
  final List<MealLog> mealLogs;
  final String? errorMessage;

  /// Mục tiêu thể chất (LoseFat/Maintain/GainMuscle…) để hiện khuyến nghị calo/thâm hụt.
  final String? fitnessGoal;

  NutritionDiaryState copyWith({
    NutritionDiaryStatus? status,
    DateTime? selectedDate,
    DailyNutritionSummary? summary,
    List<MealLog>? mealLogs,
    String? errorMessage,
    String? fitnessGoal,
  }) =>
      NutritionDiaryState(
        status: status ?? this.status,
        selectedDate: selectedDate ?? this.selectedDate,
        summary: summary ?? this.summary,
        mealLogs: mealLogs ?? this.mealLogs,
        errorMessage: errorMessage,
        fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      );

  @override
  List<Object?> get props =>
      [status, selectedDate, summary, mealLogs, errorMessage, fitnessGoal];
}
