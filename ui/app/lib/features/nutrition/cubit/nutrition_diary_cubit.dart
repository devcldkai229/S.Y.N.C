import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/safe_emit.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';

part 'nutrition_diary_state.dart';

class NutritionDiaryCubit extends Cubit<NutritionDiaryState> with SafeEmitMixin<NutritionDiaryState> {
  NutritionDiaryCubit(this._api) : super(NutritionDiaryState(selectedDate: DateTime.now()));

  final NutritionRemoteDataSource _api;
  bool _waterBusy = false;

  Future<void> load({DateTime? date}) async {
    final target = date ?? state.selectedDate;
    safeEmit(state.copyWith(status: NutritionDiaryStatus.loading, selectedDate: target));
    try {
      final results = await Future.wait([
        _api.fetchDailySummary(target),
        _api.fetchMealLogs(target),
      ]);
      safeEmit(state.copyWith(
        status: NutritionDiaryStatus.loaded,
        summary: results[0] as DailyNutritionSummary,
        mealLogs: results[1] as List<MealLog>,
        errorMessage: null,
      ));
    } catch (e) {
      safeEmit(state.copyWith(
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
    if (_waterBusy) return;
    _waterBusy = true;

    final previous = state.summary;
    if (previous != null) {
      safeEmit(state.copyWith(
        summary: previous.copyWith(waterIntakeMl: previous.waterIntakeMl + 250),
      ));
    }

    try {
      final summary = await _api.addWater(250, state.selectedDate);
      safeEmit(state.copyWith(summary: summary));
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Rate-limited — keep optimistic value; server will catch up on next load.
      } else if (previous != null) {
        safeEmit(state.copyWith(summary: previous));
      }
    } catch (_) {
      if (previous != null) safeEmit(state.copyWith(summary: previous));
    } finally {
      _waterBusy = false;
    }
  }

  Future<void> refreshAfterMealLogged({DateTime? date}) async {
    final target = date ?? state.selectedDate;
    final sameDay = target.year == state.selectedDate.year &&
        target.month == state.selectedDate.month &&
        target.day == state.selectedDate.day;
    if (sameDay) {
      await load(date: state.selectedDate);
    }
  }

  Future<void> deleteMealLog(String id) async {
    final previous = state.mealLogs;
    safeEmit(state.copyWith(
      mealLogs: previous.where((l) => l.id != id).toList(),
    ));
    try {
      await _api.deleteMealLog(id);
      await load();
    } catch (_) {
      safeEmit(state.copyWith(mealLogs: previous));
    }
  }

  List<MealLog> logsForMeal(String mealType) =>
      state.mealLogs.where((l) => l.mealType == mealType).toList();
}
