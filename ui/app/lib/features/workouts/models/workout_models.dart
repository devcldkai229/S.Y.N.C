class PersonalizedRoadmap {
  PersonalizedRoadmap({
    required this.id,
    required this.roadmapName,
    required this.fitnessGoal,
    required this.currentPhase,
    required this.startDate,
    this.expectedEndDate,
    required this.roadmapStatus,
  });

  final String id;
  final String roadmapName;
  final String fitnessGoal;
  final String currentPhase;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final String roadmapStatus;

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
  });

  final String id;
  final String roadmapId;
  final DateTime scheduledDate;
  final String sessionTitle;
  final String sessionType;
  final int estimatedDurationMinutes;
  final String sessionStatus;
  final bool aiGenerated;

  bool get isCompleted => sessionStatus.toLowerCase().contains('completed');
  bool get isInProgress => sessionStatus.toLowerCase().contains('inprogress');

  factory RoadmapSession.fromJson(Map<String, dynamic> json) {
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
    );
  }

  String get energyDemandLabel {
    final t = sessionType.toLowerCase();
    if (t.contains('recovery') || t.contains('mobility')) return 'Low';
    if (estimatedDurationMinutes >= 60) return 'Extreme';
    if (estimatedDurationMinutes >= 45) return 'High';
    return 'Moderate';
  }
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
