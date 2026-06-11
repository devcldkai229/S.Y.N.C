part of 'nutrition_diary_cubit.dart';

enum NutritionDiaryStatus { initial, loading, loaded, error }

class NutritionDiaryState extends Equatable {
  const NutritionDiaryState({
    this.status = NutritionDiaryStatus.initial,
    required this.selectedDate,
    this.summary,
    this.mealLogs = const [],
    this.errorMessage,
  });

  final NutritionDiaryStatus status;
  final DateTime selectedDate;
  final DailyNutritionSummary? summary;
  final List<MealLog> mealLogs;
  final String? errorMessage;

  NutritionDiaryState copyWith({
    NutritionDiaryStatus? status,
    DateTime? selectedDate,
    DailyNutritionSummary? summary,
    List<MealLog>? mealLogs,
    String? errorMessage,
  }) =>
      NutritionDiaryState(
        status: status ?? this.status,
        selectedDate: selectedDate ?? this.selectedDate,
        summary: summary ?? this.summary,
        mealLogs: mealLogs ?? this.mealLogs,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, selectedDate, summary, mealLogs, errorMessage];
}
