class PersonalizedRoadmap {
  PersonalizedRoadmap({
    required this.id,
    required this.roadmapName,
    required this.fitnessGoal,
    required this.currentPhase,
    required this.startDate,
    this.expectedEndDate,
    required this.roadmapStatus,
    this.currentWeightKg = 0,
    this.targetWeightKg = 0,
    this.adaptiveAiEnabled = true,
  });

  final String id;
  final String roadmapName;
  final String fitnessGoal;
  final String currentPhase;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final String roadmapStatus;
  final double currentWeightKg;
  final double targetWeightKg;
  final bool adaptiveAiEnabled;

  bool get isActive => roadmapStatus.toLowerCase().contains('active');

  factory PersonalizedRoadmap.fromJson(Map<String, dynamic> json) {
    return PersonalizedRoadmap(
      id: json['id']?.toString() ?? '',
      roadmapName: (json['roadmapName'] ?? '').toString(),
      fitnessGoal: (json['fitnessGoal'] ?? '').toString(),
      currentPhase: (json['currentPhase'] ?? '').toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      expectedEndDate: json['expectedEndDate'] != null
          ? DateTime.tryParse(json['expectedEndDate'].toString())
          : null,
      roadmapStatus: _enumLabel(json['roadmapStatus']),
      currentWeightKg: _toDouble(json['currentWeightKg']),
      targetWeightKg: _toDouble(json['targetWeightKg']),
      adaptiveAiEnabled: json['adaptiveAiEnabled'] != false,
    );
  }
}

class RoadmapSession {
  RoadmapSession({
    required this.id,
    required this.roadmapId,
    required this.scheduledDate,
    required this.sessionTitle,
    required this.sessionType,
    required this.estimatedDurationMinutes,
    required this.sessionStatus,
    required this.aiGenerated,
    this.scheduledTime = '',
    this.exerciseCount = 0,
    this.executionBlocks = const [],
  });

  final String id;
  final String roadmapId;
  final DateTime scheduledDate;
  final String sessionTitle;
  final String sessionType;
  final int estimatedDurationMinutes;
  final String sessionStatus;
  final bool aiGenerated;
  final String scheduledTime;
  final int exerciseCount;
  final List<SessionExecutionBlock> executionBlocks;

  bool get isCompleted => sessionStatus.toLowerCase().contains('completed');
  bool get isInProgress => sessionStatus.toLowerCase().contains('inprogress');

  factory RoadmapSession.fromJson(Map<String, dynamic> json) {
    final blocks = json['executionBlocks'];
    final blockCount = blocks is List ? blocks.length : 0;
    return RoadmapSession(
      id: json['id']?.toString() ?? '',
      roadmapId: json['roadmapId']?.toString() ?? '',
      scheduledDate:
          DateTime.tryParse(json['scheduledDate']?.toString() ?? '') ?? DateTime.now(),
      sessionTitle: (json['sessionTitle'] ?? 'Workout').toString(),
      sessionType: (json['sessionType'] ?? 'Strength').toString(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] ?? 45) as int,
      sessionStatus: _enumLabel(json['sessionStatus']),
      aiGenerated: json['aiGenerated'] == true,
      scheduledTime: (json['scheduledTime'] ?? '').toString(),
      exerciseCount: blockCount,
      executionBlocks: blocks is List
          ? blocks
              .whereType<Map<String, dynamic>>()
              .map(SessionExecutionBlock.fromJson)
              .toList()
          : const [],
    );
  }

  String get energyDemandLabel {
    final t = sessionType.toLowerCase();
    if (t.contains('recovery') || t.contains('mobility')) return 'Low';
    if (estimatedDurationMinutes >= 60) return 'Extreme';
    if (estimatedDurationMinutes >= 45) return 'High';
    return 'Moderate';
  }

  String get subtitleLine {
    final parts = <String>[
      '$estimatedDurationMinutes min',
      'Energy: $energyDemandLabel',
    ];
    if (exerciseCount > 0) parts.add('$exerciseCount exercises');
    if (scheduledTime.isNotEmpty) parts.add(scheduledTime);
    return parts.join(' • ');
  }
}

class SessionExecutionBlock {
  SessionExecutionBlock({
    required this.order,
    required this.exerciseId,
    required this.exerciseName,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeightKg,
    required this.restSeconds,
    this.exerciseNotes,
  });

  final int order;
  final String exerciseId;
  final String exerciseName;
  final int targetSets;
  final int targetReps;
  final double targetWeightKg;
  final int restSeconds;
  final String? exerciseNotes;

  factory SessionExecutionBlock.fromJson(Map<String, dynamic> json) {
    return SessionExecutionBlock(
      order: (json['order'] ?? 0) as int,
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseName: (json['exerciseName'] ?? '').toString(),
      targetSets: (json['targetSets'] ?? 0) as int,
      targetReps: (json['targetReps'] ?? 0) as int,
      targetWeightKg: _toDouble(json['targetWeightKg']),
      restSeconds: (json['restSeconds'] ?? 0) as int,
      exerciseNotes: json['exerciseNotes']?.toString(),
    );
  }
}

class UserCustomWorkout {
  UserCustomWorkout({
    required this.id,
    required this.workoutName,
    required this.scheduleMode,
    required this.visibility,
    required this.allowAiOptimization,
    required this.blocks,
    required this.createdAt,
    this.coverRoadmapImageUrl,
    this.parentWorkoutId,
    this.savesCount = 0,
    this.sessions = const [],
  });

  final String id;
  final String workoutName;
  final String? coverRoadmapImageUrl;
  final String scheduleMode;
  final String visibility;
  final bool allowAiOptimization;
  final List<CustomWorkoutBlock> blocks;
  final DateTime createdAt;
  final String? parentWorkoutId;
  final int savesCount;
  final List<WorkoutSessionDetail> sessions;

  int get totalSets => sessions.fold(0, (sum, s) => sum + s.totalSetCount);
  int get exerciseCount => sessions.fold(0, (sum, s) => sum + s.exerciseCount);

  factory UserCustomWorkout.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['customBlocks'];
    final rawSessions = json['sessions'];
    return UserCustomWorkout(
      id: json['id']?.toString() ?? '',
      workoutName: (json['workoutName'] ?? 'Custom Workout').toString(),
      coverRoadmapImageUrl: json['coverRoadmapImageUrl']?.toString(),
      scheduleMode: (json['scheduleMode'] ?? '').toString(),
      visibility: _enumLabel(json['visibility']),
      allowAiOptimization: json['allowAiOptimization'] == true,
      blocks: rawBlocks is List
          ? rawBlocks
              .whereType<Map<String, dynamic>>()
              .map(CustomWorkoutBlock.fromJson)
              .toList()
          : const [],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      parentWorkoutId: json['parentWorkoutId']?.toString(),
      savesCount: _toInt(json['savesCount']),
      sessions: rawSessions is List
          ? rawSessions
              .whereType<Map<String, dynamic>>()
              .map(WorkoutSessionDetail.fromJson)
              .toList()
          : const [],
    );
  }
}

class CustomWorkoutBlock {
  CustomWorkoutBlock({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
  });

  final String exerciseId;
  final int sets;
  final int reps;
  final double weightKg;
  final int restSeconds;

  factory CustomWorkoutBlock.fromJson(Map<String, dynamic> json) {
    return CustomWorkoutBlock(
      exerciseId: json['exerciseId']?.toString() ?? '',
      sets: (json['sets'] ?? 0) as int,
      reps: (json['reps'] ?? 0) as int,
      weightKg: _toDouble(json['weightKg']),
      restSeconds: (json['restSeconds'] ?? 0) as int,
    );
  }

  String get summary => '$sets×$reps @ ${weightKg.toStringAsFixed(weightKg.truncateToDouble() == weightKg ? 0 : 1)}kg';
}

class RecoveryProfile {
  RecoveryProfile({
    required this.fatigueLevel,
    required this.muscleSorenessScore,
    required this.currentRecoveryScore,
    required this.recommendedTrainingIntensity,
  });

  final int fatigueLevel;
  final int muscleSorenessScore;
  final int currentRecoveryScore;
  final String recommendedTrainingIntensity;

  String get systemFatigueLabel => _scoreToLabel(fatigueLevel, invert: true);
  String get muscleSorenessLabel => _scoreToLabel(muscleSorenessScore, invert: true);

  factory RecoveryProfile.fromJson(Map<String, dynamic> json) {
    return RecoveryProfile(
      fatigueLevel: (json['fatigueLevel'] ?? 0) as int,
      muscleSorenessScore: (json['muscleSorenessScore'] ?? 0) as int,
      currentRecoveryScore: (json['currentRecoveryScore'] ?? 0) as int,
      recommendedTrainingIntensity:
          (json['recommendedTrainingIntensity'] ?? '').toString(),
    );
  }
}

class ExerciseCatalogItem {
  ExerciseCatalogItem({
    required this.id,
    required this.exerciseCode,
    required this.nameEn,
    required this.nameVi,
    required this.category,
    required this.difficulty,
    required this.movementPattern,
    required this.bodyRegion,
    required this.primaryMuscles,
    required this.equipmentRequired,
    required this.estimatedCaloriesPerMinute,
    required this.metValue,
    required this.aiCoachingCues,
    this.thumbnailUrl,
    this.isAiRecommended = false,
  });

  final String id;
  final String exerciseCode;
  final String nameEn;
  final String nameVi;
  final String category;
  final String difficulty;
  final String movementPattern;
  final String bodyRegion;
  final List<String> primaryMuscles;
  final List<String> equipmentRequired;
  final int estimatedCaloriesPerMinute;
  final double metValue;
  final List<String> aiCoachingCues;
  final String? thumbnailUrl;
  final bool isAiRecommended;

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> json) {
    final cues = _stringList(json['aiCoachingCues']);
    final goals = _stringList(json['recommendedGoals']);
    return ExerciseCatalogItem(
      id: json['id']?.toString() ?? '',
      exerciseCode: (json['exerciseCode'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      nameVi: (json['nameVi'] ?? '').toString(),
      category: _enumLabel(json['category']),
      difficulty: _enumLabel(json['difficulty']),
      movementPattern: _enumLabel(json['movementPattern']),
      bodyRegion: _enumLabel(json['bodyRegion']),
      primaryMuscles: _stringList(json['primaryMuscles']),
      equipmentRequired: _stringList(json['equipmentRequired']),
      estimatedCaloriesPerMinute: (json['estimatedCaloriesPerMinute'] ?? 0) as int,
      metValue: (json['metValue'] is num) ? (json['metValue'] as num).toDouble() : 0,
      aiCoachingCues: cues,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      isAiRecommended: json['isAiRecommended'] == true || (cues.isNotEmpty && goals.isNotEmpty),
    );
  }

  String get bodyRegionGroupTitle => _humanizeEnum(bodyRegion.isNotEmpty ? bodyRegion : movementPattern);

  String get patternGroupTitle {
    final p = movementPattern;
    if (p.isEmpty) return 'Other';
    return p
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
  }

  String get musclesEquipmentLine {
    final muscles = primaryMuscles.join(', ');
    final equip = equipmentRequired.join(', ');
    if (muscles.isEmpty) return equip;
    if (equip.isEmpty) return muscles;
    return '$muscles • $equip';
  }
}

/// An exercise suggested by the AIAgent service, carrying the catalog item plus
/// AI-assigned sets/reps/rest/notes. Reuses [ExerciseCatalogItem.fromJson] since
/// the AI endpoint returns the same catalog fields.
class AiSuggestedExercise {
  AiSuggestedExercise({
    required this.item,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    required this.notes,
  });

  final ExerciseCatalogItem item;
  final int sets;
  final int reps;
  final int restSeconds;
  final String notes;

  factory AiSuggestedExercise.fromJson(Map<String, dynamic> json) {
    return AiSuggestedExercise(
      item: ExerciseCatalogItem.fromJson(json),
      sets: (json['sets'] is num) ? (json['sets'] as num).toInt() : 3,
      reps: (json['reps'] is num) ? (json['reps'] as num).toInt() : 10,
      restSeconds:
          (json['restSeconds'] is num) ? (json['restSeconds'] as num).toInt() : 60,
      notes: (json['notes'] ?? '').toString(),
    );
  }
}

class ExerciseMotionAsset {
  ExerciseMotionAsset({
    required this.id,
    required this.exerciseId,
    required this.assetType,
    required this.resourceUrl,
    this.thumbnailUrl,
    this.animationDurationSeconds = 0,
  });

  final String id;
  final String exerciseId;
  final String assetType;
  final String resourceUrl;
  final String? thumbnailUrl;
  final int animationDurationSeconds;

  bool get isVideo => assetType.toLowerCase() == 'video';

  bool get isImage => assetType.toLowerCase() == 'image';

  String? get displayImageUrl {
    if (isImage && resourceUrl.isNotEmpty) return resourceUrl;
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    return null;
  }

  factory ExerciseMotionAsset.fromJson(Map<String, dynamic> json) {
    return ExerciseMotionAsset(
      id: json['id']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      assetType: _enumLabel(json['assetType']),
      resourceUrl: (json['resourceUrl'] ?? '').toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      animationDurationSeconds: (json['animationDurationSeconds'] ?? 0) as int,
    );
  }
}

class ExerciseCatalogDetail {
  ExerciseCatalogDetail({
    required this.id,
    required this.exerciseCode,
    required this.nameEn,
    required this.nameVi,
    required this.slug,
    required this.category,
    required this.difficulty,
    required this.movementPattern,
    required this.bodyRegion,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipmentRequired,
    required this.isCompound,
    required this.estimatedCaloriesPerMinute,
    required this.metValue,
    required this.recommendedRestSeconds,
    required this.aiCoachingCues,
    required this.commonMistakes,
    required this.contraindications,
    required this.recommendedGoals,
    required this.movementTags,
    required this.requiresSpotter,
    required this.motionAssets,
  });

  final String id;
  final String exerciseCode;
  final String nameEn;
  final String nameVi;
  final String slug;
  final String category;
  final String difficulty;
  final String movementPattern;
  final String bodyRegion;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> equipmentRequired;
  final bool isCompound;
  final int estimatedCaloriesPerMinute;
  final double metValue;
  final int recommendedRestSeconds;
  final List<String> aiCoachingCues;
  final List<String> commonMistakes;
  final List<String> contraindications;
  final List<String> recommendedGoals;
  final List<String> movementTags;
  final bool requiresSpotter;
  final List<ExerciseMotionAsset> motionAssets;

  List<ExerciseMotionAsset> get videoAssets =>
      motionAssets.where((a) => a.isVideo && a.resourceUrl.isNotEmpty).toList();

  List<ExerciseMotionAsset> get imageAssets => motionAssets
      .where((a) => a.isImage && a.resourceUrl.isNotEmpty)
      .toList();

  List<String> get imageUrls => imageAssets
      .map((a) => a.displayImageUrl)
      .whereType<String>()
      .where((url) => url.isNotEmpty)
      .toList();

  String? get heroThumbnailUrl {
    final video = videoAssets.isNotEmpty ? videoAssets.first : null;
    if (video?.thumbnailUrl != null && video!.thumbnailUrl!.isNotEmpty) {
      return video.thumbnailUrl;
    }
    if (imageAssets.isNotEmpty) return imageAssets.first.resourceUrl;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  factory ExerciseCatalogDetail.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['motionAssets'];
    return ExerciseCatalogDetail(
      id: json['id']?.toString() ?? '',
      exerciseCode: (json['exerciseCode'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      nameVi: (json['nameVi'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      category: _enumLabel(json['category']),
      difficulty: _enumLabel(json['difficulty']),
      movementPattern: _enumLabel(json['movementPattern']),
      bodyRegion: _enumLabel(json['bodyRegion']),
      primaryMuscles: _stringList(json['primaryMuscles']),
      secondaryMuscles: _stringList(json['secondaryMuscles']),
      equipmentRequired: _stringList(json['equipmentRequired']),
      isCompound: json['isCompound'] == true,
      estimatedCaloriesPerMinute: (json['estimatedCaloriesPerMinute'] ?? 0) as int,
      metValue: (json['metValue'] is num) ? (json['metValue'] as num).toDouble() : 0,
      recommendedRestSeconds: (json['recommendedRestSeconds'] ?? 0) as int,
      aiCoachingCues: _stringList(json['aiCoachingCues']),
      commonMistakes: _stringList(json['commonMistakes']),
      contraindications: _stringList(json['contraindications']),
      recommendedGoals: _stringList(json['recommendedGoals']),
      movementTags: _stringList(json['movementTags']),
      requiresSpotter: json['requiresSpotter'] == true,
      motionAssets: rawAssets is List
          ? rawAssets
              .whereType<Map<String, dynamic>>()
              .map(ExerciseMotionAsset.fromJson)
              .toList()
          : const [],
    );
  }
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _enumLabel(dynamic value) {
  if (value == null) return '';
  final s = value.toString();
  if (s.contains('.')) return s.split('.').last;
  return s;
}

String _humanizeEnum(String value) {
  if (value.isEmpty) return 'Other';
  return value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAll('_', ' ');
}

List<String> _stringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

String _scoreToLabel(int score, {bool invert = false}) {
  final s = invert ? 10 - score.clamp(0, 10) : score;
  if (s <= 3) return 'Low';
  if (s <= 6) return 'Mild';
  if (s <= 8) return 'Moderate';
  return 'High';
}

class MyWorkoutDetail {
  MyWorkoutDetail({
    required this.id,
    required this.workoutName,
    required this.visibility,
    required this.scheduleMode,
    required this.allowAiOptimization,
    required this.sessions,
    required this.weeklySchedules,
    this.parentWorkoutId,
    this.savesCount = 0,
  });

  final String id;
  final String workoutName;
  final String visibility;
  final String scheduleMode;
  final bool allowAiOptimization;
  final List<WorkoutSessionDetail> sessions;
  final List<ScheduledWorkoutDetail> weeklySchedules;
  final String? parentWorkoutId;
  final int savesCount;

  factory MyWorkoutDetail.fromJson(Map<String, dynamic> json) {
    final rawSessions = json['sessions'];
    final rawSchedules = json['weeklySchedules'];
    return MyWorkoutDetail(
      id: json['id']?.toString() ?? '',
      workoutName: (json['workoutName'] ?? '').toString(),
      visibility: _enumLabel(json['visibility']),
      scheduleMode: (json['scheduleMode'] ?? '').toString(),
      allowAiOptimization: json['allowAiOptimization'] == true,
      sessions: rawSessions is List
          ? rawSessions
              .whereType<Map<String, dynamic>>()
              .map(WorkoutSessionDetail.fromJson)
              .toList()
          : const [],
      weeklySchedules: rawSchedules is List
          ? rawSchedules
              .whereType<Map<String, dynamic>>()
              .map(ScheduledWorkoutDetail.fromJson)
              .toList()
          : const [],
      parentWorkoutId: json['parentWorkoutId']?.toString(),
      savesCount: _toInt(json['savesCount']),
    );
  }
}

class WorkoutSessionDetail {
  WorkoutSessionDetail({
    required this.id,
    required this.sessionTitle,
    required this.exerciseCount,
    required this.totalSetCount,
  });

  final String id;
  final String sessionTitle;
  final int exerciseCount;
  final int totalSetCount;

  factory WorkoutSessionDetail.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionDetail(
      id: json['id']?.toString() ?? '',
      sessionTitle: (json['sessionTitle'] ?? '').toString(),
      exerciseCount: (json['exerciseCount'] ?? 0) as int,
      totalSetCount: (json['totalSetCount'] ?? 0) as int,
    );
  }
}

class ScheduledWorkoutDetail {
  ScheduledWorkoutDetail({
    required this.id,
    required this.sessionId,
    required this.sessionTitle,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.repeatPattern,
    required this.status,
  });

  final String id;
  final String sessionId;
  final String sessionTitle;
  final DateTime scheduledStartTime;
  final DateTime scheduledEndTime;
  final String repeatPattern;
  final String status;

  factory ScheduledWorkoutDetail.fromJson(Map<String, dynamic> json) {
    return ScheduledWorkoutDetail(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      sessionTitle: (json['sessionTitle'] ?? '').toString(),
      scheduledStartTime: DateTime.tryParse(json['scheduledStartTime']?.toString() ?? '') ?? DateTime.now(),
      scheduledEndTime: DateTime.tryParse(json['scheduledEndTime']?.toString() ?? '') ?? DateTime.now(),
      repeatPattern: (json['repeatPattern'] ?? '').toString(),
      status: _enumLabel(json['status']),
    );
  }
}

class WorkoutExecutionDetail {
  WorkoutExecutionDetail({
    required this.executionId,
    required this.sessionId,
    required this.sessionTitle,
    required this.startedAt,
    this.energyLevelBefore,
    required this.exercises,
  });

  final String executionId;
  final String sessionId;
  final String sessionTitle;
  final DateTime startedAt;
  final int? energyLevelBefore;
  final List<ExecutionExercise> exercises;

  factory WorkoutExecutionDetail.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return WorkoutExecutionDetail(
      executionId: json['executionId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      sessionTitle: (json['sessionTitle'] ?? '').toString(),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
      energyLevelBefore: json['energyLevelBefore'] as int?,
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map<String, dynamic>>()
              .map(ExecutionExercise.fromJson)
              .toList()
          : const [],
    );
  }
}

class ExecutionExercise {
  ExecutionExercise({
    required this.exerciseId,
    required this.exerciseName,
    this.exerciseAssetId,
    required this.order,
    required this.sets,
  });

  final String exerciseId;
  final String exerciseName;
  final String? exerciseAssetId;
  final int order;
  final List<ExerciseSetLog> sets;

  factory ExecutionExercise.fromJson(Map<String, dynamic> json) {
    final rawSets = json['sets'];
    return ExecutionExercise(
      exerciseId: json['exerciseId']?.toString() ?? '',
      exerciseName: (json['exerciseName'] ?? '').toString(),
      exerciseAssetId: json['exerciseAssetId']?.toString(),
      order: (json['order'] ?? 0) as int,
      sets: rawSets is List
          ? rawSets
              .whereType<Map<String, dynamic>>()
              .map(ExerciseSetLog.fromJson)
              .toList()
          : const [],
    );
  }
}

class ExerciseSetLog {
  ExerciseSetLog({
    required this.id,
    required this.executionId,
    required this.exerciseId,
    required this.setNumber,
    required this.targetReps,
    required this.actualReps,
    required this.weightKg,
    required this.rir,
    required this.restTakenSeconds,
    required this.formScore,
    required this.completed,
  });

  final String id;
  final String executionId;
  final String exerciseId;
  final int setNumber;
  final int targetReps;
  final int actualReps;
  final double weightKg;
  final int rir;
  final int restTakenSeconds;
  final int formScore;
  final bool completed;

  factory ExerciseSetLog.fromJson(Map<String, dynamic> json) {
    return ExerciseSetLog(
      id: json['id']?.toString() ?? '',
      executionId: json['executionId']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? '',
      setNumber: (json['setNumber'] ?? 0) as int,
      targetReps: (json['targetReps'] ?? 0) as int,
      actualReps: (json['actualReps'] ?? 0) as int,
      weightKg: _toDouble(json['weightKg']),
      rir: (json['rir'] ?? 0) as int,
      restTakenSeconds: (json['restTakenSeconds'] ?? 0) as int,
      formScore: (json['formScore'] ?? 0) as int,
      completed: json['completed'] == true,
    );
  }
}

class WorkoutExecutionSummary {
  WorkoutExecutionSummary({
    required this.executionId,
    required this.sessionId,
    required this.sessionTitle,
    required this.startedAt,
    required this.completedAt,
    required this.actualDurationMinutes,
    required this.completionRate,
    required this.completedSetCount,
    required this.totalSetCount,
    required this.skippedExerciseCount,
    this.perceivedDifficulty,
    this.energyLevelBefore,
    this.energyLevelAfter,
    required this.caloriesBurned,
    required this.aiCoachFeedback,
    this.sessionFeedback,
  });

  final String executionId;
  final String sessionId;
  final String sessionTitle;
  final DateTime startedAt;
  final DateTime completedAt;
  final int actualDurationMinutes;
  final double completionRate;
  final int completedSetCount;
  final int totalSetCount;
  final int skippedExerciseCount;
  final int? perceivedDifficulty;
  final int? energyLevelBefore;
  final int? energyLevelAfter;
  final double caloriesBurned;
  final String aiCoachFeedback;
  final String? sessionFeedback;

  factory WorkoutExecutionSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutExecutionSummary(
      executionId: json['executionId']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      sessionTitle: (json['sessionTitle'] ?? '').toString(),
      startedAt: DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt']?.toString() ?? '') ?? DateTime.now(),
      actualDurationMinutes: (json['actualDurationMinutes'] ?? 0) as int,
      completionRate: _toDouble(json['completionRate']),
      completedSetCount: (json['completedSetCount'] ?? 0) as int,
      totalSetCount: (json['totalSetCount'] ?? 0) as int,
      skippedExerciseCount: (json['skippedExerciseCount'] ?? 0) as int,
      perceivedDifficulty: json['perceivedDifficulty'] as int?,
      energyLevelBefore: json['energyLevelBefore'] as int?,
      energyLevelAfter: json['energyLevelAfter'] as int?,
      caloriesBurned: _toDouble(json['caloriesBurned']),
      aiCoachFeedback: (json['aiCoachFeedback'] ?? '').toString(),
      sessionFeedback: json['sessionFeedback']?.toString(),
    );
  }
}
