part of 'workouts_cubit.dart';

enum LoadStatus { initial, loading, success, failure }

class WorkoutsState extends Equatable {
  const WorkoutsState({
    this.roadmapStatus = LoadStatus.initial,
    this.customStatus = LoadStatus.initial,
    this.catalogStatus = LoadStatus.initial,
    this.exploreStatus = LoadStatus.initial,
    this.roadmap,
    this.sessions = const [],
    this.recovery,
    this.customWorkouts = const [],
    this.exploreWorkouts = const [],
    this.exercises = const [],
    this.roadmapError,
    this.customError,
    this.catalogError,
    this.exploreError,
    this.customSessions = const {},
  });

  const WorkoutsState.initial() : this();

  final LoadStatus roadmapStatus;
  final LoadStatus customStatus;
  final LoadStatus catalogStatus;
  final LoadStatus exploreStatus;
  final PersonalizedRoadmap? roadmap;
  final List<RoadmapSession> sessions;
  final RecoveryProfile? recovery;
  final List<UserCustomWorkout> customWorkouts;
  final List<UserCustomWorkout> exploreWorkouts;
  final List<ExerciseCatalogItem> exercises;
  final String? roadmapError;
  final String? customError;
  final String? catalogError;
  final String? exploreError;
  final Map<String, List<RoadmapSession>> customSessions;

  WorkoutsState copyWith({
    LoadStatus? roadmapStatus,
    LoadStatus? customStatus,
    LoadStatus? catalogStatus,
    LoadStatus? exploreStatus,
    PersonalizedRoadmap? roadmap,
    List<RoadmapSession>? sessions,
    RecoveryProfile? recovery,
    List<UserCustomWorkout>? customWorkouts,
    List<UserCustomWorkout>? exploreWorkouts,
    List<ExerciseCatalogItem>? exercises,
    String? roadmapError,
    String? customError,
    String? catalogError,
    String? exploreError,
    Map<String, List<RoadmapSession>>? customSessions,
    bool clearRoadmapError = false,
    bool clearCustomError = false,
    bool clearCatalogError = false,
    bool clearExploreError = false,
  }) {
    return WorkoutsState(
      roadmapStatus: roadmapStatus ?? this.roadmapStatus,
      customStatus: customStatus ?? this.customStatus,
      catalogStatus: catalogStatus ?? this.catalogStatus,
      exploreStatus: exploreStatus ?? this.exploreStatus,
      roadmap: roadmap ?? this.roadmap,
      sessions: sessions ?? this.sessions,
      recovery: recovery ?? this.recovery,
      customWorkouts: customWorkouts ?? this.customWorkouts,
      exploreWorkouts: exploreWorkouts ?? this.exploreWorkouts,
      exercises: exercises ?? this.exercises,
      roadmapError: clearRoadmapError ? null : (roadmapError ?? this.roadmapError),
      customError: clearCustomError ? null : (customError ?? this.customError),
      catalogError: clearCatalogError ? null : (catalogError ?? this.catalogError),
      exploreError: clearExploreError ? null : (exploreError ?? this.exploreError),
      customSessions: customSessions ?? this.customSessions,
    );
  }

  @override
  List<Object?> get props => [
        roadmapStatus,
        customStatus,
        catalogStatus,
        exploreStatus,
        roadmap,
        sessions,
        recovery,
        customWorkouts,
        exploreWorkouts,
        exercises,
        roadmapError,
        customError,
        catalogError,
        exploreError,
        customSessions,
      ];
}
