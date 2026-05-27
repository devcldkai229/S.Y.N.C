part of 'workouts_cubit.dart';

enum LoadStatus { initial, loading, success, failure }

class WorkoutsState extends Equatable {
  const WorkoutsState({
    this.roadmapStatus = LoadStatus.initial,
    this.catalogStatus = LoadStatus.initial,
    this.roadmap,
    this.sessions = const [],
    this.recovery,
    this.exercises = const [],
    this.roadmapError,
    this.catalogError,
  });

  const WorkoutsState.initial() : this();

  final LoadStatus roadmapStatus;
  final LoadStatus catalogStatus;
  final PersonalizedRoadmap? roadmap;
  final List<RoadmapSession> sessions;
  final RecoveryProfile? recovery;
  final List<ExerciseCatalogItem> exercises;
  final String? roadmapError;
  final String? catalogError;

  WorkoutsState copyWith({
    LoadStatus? roadmapStatus,
    LoadStatus? catalogStatus,
    PersonalizedRoadmap? roadmap,
    List<RoadmapSession>? sessions,
    RecoveryProfile? recovery,
    List<ExerciseCatalogItem>? exercises,
    String? roadmapError,
    String? catalogError,
    bool clearRoadmapError = false,
    bool clearCatalogError = false,
  }) {
    return WorkoutsState(
      roadmapStatus: roadmapStatus ?? this.roadmapStatus,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      roadmap: roadmap ?? this.roadmap,
      sessions: sessions ?? this.sessions,
      recovery: recovery ?? this.recovery,
      exercises: exercises ?? this.exercises,
      roadmapError: clearRoadmapError ? null : (roadmapError ?? this.roadmapError),
      catalogError: clearCatalogError ? null : (catalogError ?? this.catalogError),
    );
  }

  @override
  List<Object?> get props => [
        roadmapStatus,
        catalogStatus,
        roadmap,
        sessions,
        recovery,
        exercises,
        roadmapError,
        catalogError,
      ];
}
