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

class UserCustomWorkout {
  UserCustomWorkout({
    required this.id,
    required this.workoutName,
    required this.scheduleMode,
    required this.visibility,
    required this.allowAiOptimization,
    required this.blocks,
    required this.createdAt,
  });

  final String id;
  final String workoutName;
  final String scheduleMode;
  final String visibility;
  final bool allowAiOptimization;
  final List<CustomWorkoutBlock> blocks;
  final DateTime createdAt;

  int get totalSets => blocks.fold(0, (sum, b) => sum + b.sets);
  int get exerciseCount => blocks.length;

  factory UserCustomWorkout.fromJson(Map<String, dynamic> json) {
    final rawBlocks = json['customBlocks'];
    return UserCustomWorkout(
      id: json['id']?.toString() ?? '',
      workoutName: (json['workoutName'] ?? 'Custom Workout').toString(),
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
    required this.primaryMuscles,
    required this.equipmentRequired,
    required this.estimatedCaloriesPerMinute,
    required this.metValue,
    required this.aiCoachingCues,
  });

  final String id;
  final String exerciseCode;
  final String nameEn;
  final String nameVi;
  final String category;
  final String difficulty;
  final String movementPattern;
  final List<String> primaryMuscles;
  final List<String> equipmentRequired;
  final int estimatedCaloriesPerMinute;
  final double metValue;
  final List<String> aiCoachingCues;

  factory ExerciseCatalogItem.fromJson(Map<String, dynamic> json) {
    return ExerciseCatalogItem(
      id: json['id']?.toString() ?? '',
      exerciseCode: (json['exerciseCode'] ?? '').toString(),
      nameEn: (json['nameEn'] ?? '').toString(),
      nameVi: (json['nameVi'] ?? '').toString(),
      category: _enumLabel(json['category']),
      difficulty: _enumLabel(json['difficulty']),
      movementPattern: _enumLabel(json['movementPattern']),
      primaryMuscles: _stringList(json['primaryMuscles']),
      equipmentRequired: _stringList(json['equipmentRequired']),
      estimatedCaloriesPerMinute: (json['estimatedCaloriesPerMinute'] ?? 0) as int,
      metValue: (json['metValue'] is num) ? (json['metValue'] as num).toDouble() : 0,
      aiCoachingCues: _stringList(json['aiCoachingCues']),
    );
  }

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

  String? get heroThumbnailUrl {
    final video = videoAssets.isNotEmpty ? videoAssets.first : null;
    if (video?.thumbnailUrl != null && video!.thumbnailUrl!.isNotEmpty) {
      return video.thumbnailUrl;
    }
    if (imageAssets.isNotEmpty) return imageAssets.first.resourceUrl;
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

String _enumLabel(dynamic value) {
  if (value == null) return '';
  final s = value.toString();
  if (s.contains('.')) return s.split('.').last;
  return s;
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
