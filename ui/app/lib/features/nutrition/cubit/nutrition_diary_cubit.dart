import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';

part 'nutrition_diary_state.dart';

class NutritionDiaryCubit extends Cubit<NutritionDiaryState> {
  NutritionDiaryCubit(this._api) : super(NutritionDiaryState(selectedDate: DateTime.now()));

  final NutritionRemoteDataSource _api;

  Future<void> load({DateTime? date}) async {
    final target = date ?? state.selectedDate;
    emit(state.copyWith(status: NutritionDiaryStatus.loading, selectedDate: target));
    try {
      final results = await Future.wait([
        _api.fetchDailySummary(target),
        _api.fetchMealLogs(target),
      ]);
      emit(state.copyWith(
        status: NutritionDiaryStatus.loaded,
        summary: results[0] as DailyNutritionSummary,
        mealLogs: results[1] as List<MealLog>,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: NutritionDiaryStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> shiftDay(int delta) async {
    final next = state.selectedDate.add(Duration(days: delta));
    await load(date: next);
  }

  Future<void> addWater() async {
    try {
      final summary = await _api.addWater(250, state.selectedDate);
      emit(state.copyWith(summary: summary));
    } catch (_) {}
  }

  Future<void> deleteMealLog(String id) async {
    final previous = state.mealLogs;
    emit(state.copyWith(
      mealLogs: previous.where((l) => l.id != id).toList(),
    ));
    try {
      await _api.deleteMealLog(id);
      await load();
    } catch (_) {
      emit(state.copyWith(mealLogs: previous));
    }
  }

  List<MealLog> logsForMeal(String mealType) =>
      state.mealLogs.where((l) => l.mealType == mealType).toList();
}
