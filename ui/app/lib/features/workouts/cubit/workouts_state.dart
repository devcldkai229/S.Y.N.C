part of 'workouts_cubit.dart';

enum LoadStatus { initial, loading, success, failure }

class WorkoutsState extends Equatable {
  const WorkoutsState({
    this.roadmapStatus = LoadStatus.initial,
    this.customStatus = LoadStatus.initial,
    this.catalogStatus = LoadStatus.initial,
    this.roadmap,
    this.sessions = const [],
    this.recovery,
    this.customWorkouts = const [],
    this.exercises = const [],
    this.roadmapError,
    this.customError,
    this.catalogError,
  });

  const WorkoutsState.initial() : this();

  final LoadStatus roadmapStatus;
  final LoadStatus customStatus;
  final LoadStatus catalogStatus;
  final PersonalizedRoadmap? roadmap;
  final List<RoadmapSession> sessions;
  final RecoveryProfile? recovery;
  final List<UserCustomWorkout> customWorkouts;
  final List<ExerciseCatalogItem> exercises;
  final String? roadmapError;
  final String? customError;
  final String? catalogError;

  WorkoutsState copyWith({
    LoadStatus? roadmapStatus,
    LoadStatus? customStatus,
    LoadStatus? catalogStatus,
    PersonalizedRoadmap? roadmap,
    List<RoadmapSession>? sessions,
    RecoveryProfile? recovery,
    List<UserCustomWorkout>? customWorkouts,
    List<ExerciseCatalogItem>? exercises,
    String? roadmapError,
    String? customError,
    String? catalogError,
    bool clearRoadmapError = false,
    bool clearCustomError = false,
    bool clearCatalogError = false,
  }) {
    return WorkoutsState(
      roadmapStatus: roadmapStatus ?? this.roadmapStatus,
      customStatus: customStatus ?? this.customStatus,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      roadmap: roadmap ?? this.roadmap,
      sessions: sessions ?? this.sessions,
      recovery: recovery ?? this.recovery,
      customWorkouts: customWorkouts ?? this.customWorkouts,
      exercises: exercises ?? this.exercises,
      roadmapError: clearRoadmapError ? null : (roadmapError ?? this.roadmapError),
      customError: clearCustomError ? null : (customError ?? this.customError),
      catalogError: clearCatalogError ? null : (catalogError ?? this.catalogError),
    );
  }

  @override
  List<Object?> get props => [
        roadmapStatus,
        customStatus,
        catalogStatus,
        roadmap,
        sessions,
        recovery,
        customWorkouts,
        exercises,
        roadmapError,
        customError,
        catalogError,
      ];
}
