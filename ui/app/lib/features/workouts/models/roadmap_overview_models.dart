/// Mobile overview DTO from GET /v1/roadmap/roadmaps/me/overview
class RoadmapOverview {
  const RoadmapOverview({
    required this.roadmapId,
    required this.roadmapName,
    required this.fitnessGoal,
    required this.currentWeek,
    required this.totalWeeks,
    required this.phases,
    required this.phaseRationaleVi,
    required this.phaseRationaleEn,
    required this.progress,
    this.readiness,
    required this.sessions,
  });

  final String roadmapId;
  final String roadmapName;
  final String fitnessGoal;
  final int currentWeek;
  final int totalWeeks;
  final List<RoadmapPhaseOverview> phases;
  final String phaseRationaleVi;
  final String phaseRationaleEn;
  final RoadmapProgressOverview progress;
  final RoadmapReadinessOverview? readiness;
  final List<RoadmapSessionOverview> sessions;

  RoadmapSessionOverview? get nextSession {
    for (final s in sessions) {
      if (s.isNextUp) return s;
    }
    for (final s in sessions) {
      if (s.status == 'Scheduled' || s.status == 'InProgress') return s;
    }
    return null;
  }

  String phaseRationale(bool isVi) => isVi ? phaseRationaleVi : phaseRationaleEn;

  factory RoadmapOverview.fromJson(Map<String, dynamic> json) {
    return RoadmapOverview(
      roadmapId: json['roadmapId']?.toString() ?? '',
      roadmapName: json['roadmapName']?.toString() ?? '',
      fitnessGoal: json['fitnessGoal']?.toString() ?? '',
      currentWeek: _asInt(json['currentWeek'], 1),
      totalWeeks: _asInt(json['totalWeeks'], 12),
      phases: (json['phases'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RoadmapPhaseOverview.fromJson)
          .toList(),
      phaseRationaleVi: json['phaseRationaleVi']?.toString() ?? '',
      phaseRationaleEn: json['phaseRationaleEn']?.toString() ?? '',
      progress: RoadmapProgressOverview.fromJson(
        json['progress'] as Map<String, dynamic>? ?? const {},
      ),
      readiness: json['readiness'] is Map<String, dynamic>
          ? RoadmapReadinessOverview.fromJson(json['readiness'] as Map<String, dynamic>)
          : null,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(RoadmapSessionOverview.fromJson)
          .toList(),
    );
  }
}

class RoadmapPhaseOverview {
  const RoadmapPhaseOverview({
    required this.key,
    required this.displayNameVi,
    required this.displayNameEn,
    required this.status,
    required this.weekFrom,
    required this.weekTo,
  });

  final String key;
  final String displayNameVi;
  final String displayNameEn;
  final String status; // Done | Current | Upcoming
  final int weekFrom;
  final int weekTo;

  bool get isCurrent => status == 'Current';
  bool get isDone => status == 'Done';

  String displayName(bool isVi) => isVi ? displayNameVi : displayNameEn;

  factory RoadmapPhaseOverview.fromJson(Map<String, dynamic> json) {
    return RoadmapPhaseOverview(
      key: json['key']?.toString() ?? '',
      displayNameVi: json['displayNameVi']?.toString() ?? '',
      displayNameEn: json['displayNameEn']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Upcoming',
      weekFrom: _asInt(json['weekFrom'], 1),
      weekTo: _asInt(json['weekTo'], 1),
    );
  }
}

class RoadmapProgressOverview {
  const RoadmapProgressOverview({
    required this.phasePercent,
    this.currentWeightKg,
    this.targetWeightKg,
  });

  final int phasePercent;
  final double? currentWeightKg;
  final double? targetWeightKg;

  factory RoadmapProgressOverview.fromJson(Map<String, dynamic> json) {
    return RoadmapProgressOverview(
      phasePercent: _asInt(json['phasePercent'], 0),
      currentWeightKg: _asDoubleOrNull(json['currentWeightKg']),
      targetWeightKg: _asDoubleOrNull(json['targetWeightKg']),
    );
  }
}

class RoadmapReadinessOverview {
  const RoadmapReadinessOverview({
    required this.level,
    required this.score,
    required this.fatigue,
    required this.soreness,
    required this.aiAdjustmentNoteVi,
    required this.aiAdjustmentNoteEn,
  });

  final String level; // Ready | Moderate | Rest
  final int score;
  final int fatigue;
  final int soreness;
  final String aiAdjustmentNoteVi;
  final String aiAdjustmentNoteEn;

  String aiNote(bool isVi) => isVi ? aiAdjustmentNoteVi : aiAdjustmentNoteEn;

  factory RoadmapReadinessOverview.fromJson(Map<String, dynamic> json) {
    return RoadmapReadinessOverview(
      level: json['level']?.toString() ?? 'Moderate',
      score: _asInt(json['score'], 50),
      fatigue: _asInt(json['fatigue'], 0),
      soreness: _asInt(json['soreness'], 0),
      aiAdjustmentNoteVi: json['aiAdjustmentNoteVi']?.toString() ?? '',
      aiAdjustmentNoteEn: json['aiAdjustmentNoteEn']?.toString() ?? '',
    );
  }
}

class RoadmapSessionOverview {
  const RoadmapSessionOverview({
    required this.id,
    required this.displayNameVi,
    required this.subtitleEn,
    required this.status,
    required this.durationMin,
    required this.exerciseCount,
    this.scheduledTime,
    required this.scheduledDate,
    required this.intensity,
    required this.isAi,
    required this.rationaleVi,
    required this.rationaleEn,
    this.isNextUp = false,
  });

  final String id;
  final String displayNameVi;
  final String subtitleEn;
  final String status;
  final int durationMin;
  final int exerciseCount;
  final String? scheduledTime;
  final DateTime scheduledDate;
  final String intensity; // Light | Moderate | High
  final bool isAi;
  final String rationaleVi;
  final String rationaleEn;
  final bool isNextUp;

  bool get isCompleted => status == 'Completed';

  String rationale(bool isVi) => isVi ? rationaleVi : rationaleEn;

  factory RoadmapSessionOverview.fromJson(Map<String, dynamic> json) {
    return RoadmapSessionOverview(
      id: json['id']?.toString() ?? '',
      displayNameVi: json['displayNameVi']?.toString() ?? '',
      subtitleEn: json['subtitleEn']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Scheduled',
      durationMin: _asInt(json['durationMin'], 0),
      exerciseCount: _asInt(json['exerciseCount'], 0),
      scheduledTime: json['scheduledTime']?.toString(),
      scheduledDate: DateTime.tryParse(json['scheduledDate']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      intensity: json['intensity']?.toString() ?? 'Moderate',
      isAi: json['isAi'] == true,
      rationaleVi: json['rationaleVi']?.toString() ?? '',
      rationaleEn: json['rationaleEn']?.toString() ?? '',
      isNextUp: json['isNextUp'] == true,
    );
  }
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _asDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
