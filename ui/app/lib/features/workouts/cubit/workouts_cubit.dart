import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

part 'workouts_state.dart';

class WorkoutsCubit extends Cubit<WorkoutsState> {
  WorkoutsCubit(this._repository) : super(const WorkoutsState.initial());

  final WorkoutRepository _repository;

  Future<void> loadRoadmap() async {
    emit(state.copyWith(roadmapStatus: LoadStatus.loading, clearRoadmapError: true));
    try {
      final result = await _repository.loadRoadmap();
      emit(state.copyWith(
        roadmapStatus: LoadStatus.success,
        roadmap: result.roadmap,
        sessions: result.sessions,
        recovery: result.recovery,
      ));
    } catch (e) {
      emit(state.copyWith(
        roadmapStatus: LoadStatus.failure,
        roadmapError: mapApiError(e),
      ));
    }
  }

  Future<void> loadCustomWorkouts() async {
    emit(state.copyWith(customStatus: LoadStatus.loading, clearCustomError: true));
    try {
      final items = await _repository.loadCustomWorkouts();
      emit(state.copyWith(customStatus: LoadStatus.success, customWorkouts: items));
    } catch (e) {
      emit(state.copyWith(
        customStatus: LoadStatus.failure,
        customError: mapApiError(e),
      ));
    }
  }

  Future<void> loadCatalog({String? query, String? category}) async {
    emit(state.copyWith(catalogStatus: LoadStatus.loading, clearCatalogError: true));
    try {
      final items = await _repository.searchCatalog(query: query, category: category);
      emit(state.copyWith(catalogStatus: LoadStatus.success, exercises: items));
    } catch (e) {
      emit(state.copyWith(
        catalogStatus: LoadStatus.failure,
        catalogError: mapApiError(e),
      ));
    }
  }

  Future<ExerciseCatalogDetail?> fetchExerciseDetail(String id) =>
      _repository.getExerciseDetail(id);
}
