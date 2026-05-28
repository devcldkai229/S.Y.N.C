class ProfileSettings {
  ProfileSettings({
    required this.userId,
    required this.basic,
    required this.fitness,
    required this.preferences,
    required this.profileCompletenessPercent,
    required this.missingProfileHints,
  });

  final String userId;
  final BasicProfile basic;
  final FitnessProfile fitness;
  final AccountPreferences preferences;
  final int profileCompletenessPercent;
  final List<String> missingProfileHints;

  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      userId: json['userId']?.toString() ?? '',
      basic: BasicProfile.fromJson(json['basic'] as Map<String, dynamic>? ?? {}),
      fitness: FitnessProfile.fromJson(json['fitness'] as Map<String, dynamic>? ?? {}),
      preferences: AccountPreferences.fromJson(
        json['preferences'] as Map<String, dynamic>? ?? {},
      ),
      profileCompletenessPercent: (json['profileCompletenessPercent'] ?? 0) as int,
      missingProfileHints: (json['missingProfileHints'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class BasicProfile {
  BasicProfile({
    required this.fullName,
    this.avatarUrl,
    required this.email,
    this.phoneNumber,
    required this.preferredLanguage,
    required this.timeZone,
    required this.role,
    required this.status,
    required this.subscriptionTier,
    required this.emailVerified,
    required this.phoneVerified,
  });

  final String fullName;
  final String? avatarUrl;
  final String email;
  final String? phoneNumber;
  final String preferredLanguage;
  final String timeZone;
  final String role;
  final String status;
  final String subscriptionTier;
  final bool emailVerified;
  final bool phoneVerified;

  factory BasicProfile.fromJson(Map<String, dynamic> json) {
    return BasicProfile(
      fullName: (json['fullName'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      email: (json['email'] ?? '').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      preferredLanguage: (json['preferredLanguage'] ?? 'en').toString(),
      timeZone: (json['timeZone'] ?? 'UTC').toString(),
      role: (json['role'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      subscriptionTier: (json['subscriptionTier'] ?? '').toString(),
      emailVerified: json['emailVerified'] == true,
      phoneVerified: json['phoneVerified'] == true,
    );
  }
}

class FitnessProfile {
  FitnessProfile({
    required this.isConfigured,
    this.gender,
    this.dateOfBirth,
    this.heightCm,
    this.currentWeightKg,
    this.targetWeightKg,
    this.currentBodyFatPercentage,
    this.goalBodyFatPercentage,
    this.muscleMassKg,
    this.fitnessGoal,
    this.activityLevel,
    this.fitnessExperienceLevel,
    this.workoutLocationPreference,
    this.baseTdee,
    this.bmr,
    this.dailyProteinTargetGram,
    this.dailyCarbTargetGram,
    this.dailyFatTargetGram,
    this.injuries = const [],
    this.medications = const [],
  });

  final bool isConfigured;
  final String? gender;
  final String? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? currentBodyFatPercentage;
  final double? goalBodyFatPercentage;
  final double? muscleMassKg;
  final String? fitnessGoal;
  final String? activityLevel;
  final String? fitnessExperienceLevel;
  final String? workoutLocationPreference;
  final int? baseTdee;
  final int? bmr;
  final int? dailyProteinTargetGram;
  final int? dailyCarbTargetGram;
  final int? dailyFatTargetGram;
  final List<String> injuries;
  final List<String> medications;

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      isConfigured: json['isConfigured'] == true,
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      heightCm: _toDouble(json['heightCm']),
      currentWeightKg: _toDouble(json['currentWeightKg']),
      targetWeightKg: _toDouble(json['targetWeightKg']),
      currentBodyFatPercentage: _toDouble(json['currentBodyFatPercentage']),
      goalBodyFatPercentage: _toDouble(json['goalBodyFatPercentage']),
      muscleMassKg: _toDouble(json['muscleMassKg']),
      fitnessGoal: json['fitnessGoal']?.toString(),
      activityLevel: json['activityLevel']?.toString(),
      fitnessExperienceLevel: json['fitnessExperienceLevel']?.toString(),
      workoutLocationPreference: json['workoutLocationPreference']?.toString(),
      baseTdee: _toInt(json['baseTDEE'] ?? json['baseTdee']),
      bmr: _toInt(json['bmr'] ?? json['BMR']),
      dailyProteinTargetGram: _toInt(json['dailyProteinTargetGram']),
      dailyCarbTargetGram: _toInt(json['dailyCarbTargetGram']),
      dailyFatTargetGram: _toInt(json['dailyFatTargetGram']),
      injuries: _stringList(json['injuries']),
      medications: _stringList(json['medications']),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'currentBodyFatPercentage': currentBodyFatPercentage,
        'goalBodyFatPercentage': goalBodyFatPercentage,
        'muscleMassKg': muscleMassKg,
        'fitnessGoal': fitnessGoal,
        'activityLevel': activityLevel,
        'fitnessExperienceLevel': fitnessExperienceLevel,
        'workoutLocationPreference': workoutLocationPreference,
        'injuries': injuries,
        'medications': medications,
      };

  FitnessProfile copyWith({
    String? gender,
    String? dateOfBirth,
    double? heightCm,
    double? currentWeightKg,
    double? targetWeightKg,
    double? currentBodyFatPercentage,
    double? goalBodyFatPercentage,
    double? muscleMassKg,
    String? fitnessGoal,
    String? activityLevel,
    String? fitnessExperienceLevel,
    String? workoutLocationPreference,
    List<String>? injuries,
    List<String>? medications,
  }) {
    return FitnessProfile(
      isConfigured: isConfigured,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      currentWeightKg: currentWeightKg ?? this.currentWeightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      currentBodyFatPercentage: currentBodyFatPercentage ?? this.currentBodyFatPercentage,
      goalBodyFatPercentage: goalBodyFatPercentage ?? this.goalBodyFatPercentage,
      muscleMassKg: muscleMassKg ?? this.muscleMassKg,
      fitnessGoal: fitnessGoal ?? this.fitnessGoal,
      activityLevel: activityLevel ?? this.activityLevel,
      fitnessExperienceLevel: fitnessExperienceLevel ?? this.fitnessExperienceLevel,
      workoutLocationPreference: workoutLocationPreference ?? this.workoutLocationPreference,
      baseTdee: baseTdee,
      bmr: bmr,
      dailyProteinTargetGram: dailyProteinTargetGram,
      dailyCarbTargetGram: dailyCarbTargetGram,
      dailyFatTargetGram: dailyFatTargetGram,
      injuries: injuries ?? this.injuries,
      medications: medications ?? this.medications,
    );
  }
}

class AllergyItem {
  AllergyItem({required this.allergenName, this.severity, this.notes});

  final String allergenName;
  final String? severity;
  final String? notes;

  factory AllergyItem.fromJson(Map<String, dynamic> json) {
    return AllergyItem(
      allergenName: (json['allergenName'] ?? '').toString(),
      severity: json['severity']?.toString(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'allergenName': allergenName,
        if (severity != null) 'severity': severity,
        if (notes != null) 'notes': notes,
      };
}

class AccountPreferences {
  AccountPreferences({
    required this.isConfigured,
    this.allergies = const [],
    this.favoriteFoods = const [],
    this.dislikedFoods = const [],
    required this.agentPersona,
    required this.motivationStyle,
    this.autoOrderEnabled = false,
    this.maxAutoOrderLimitDaily,
    this.maxAutoOrderLimitPerOrder,
    required this.dataSharingConsent,
    required this.marketingConsent,
  });

  final bool isConfigured;
  final List<AllergyItem> allergies;
  final List<String> favoriteFoods;
  final List<String> dislikedFoods;
  final String agentPersona;
  final String motivationStyle;
  final bool autoOrderEnabled;
  final double? maxAutoOrderLimitDaily;
  final double? maxAutoOrderLimitPerOrder;
  final bool dataSharingConsent;
  final bool marketingConsent;

  factory AccountPreferences.fromJson(Map<String, dynamic> json) {
    return AccountPreferences(
      isConfigured: json['isConfigured'] == true,
      allergies: (json['allergies'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AllergyItem.fromJson)
          .toList(),
      favoriteFoods: _stringList(json['favoriteFoods']),
      dislikedFoods: _stringList(json['dislikedFoods']),
      agentPersona: (json['agentPersona'] ?? '').toString(),
      motivationStyle: (json['motivationStyle'] ?? '').toString(),
      autoOrderEnabled: json['autoOrderEnabled'] == true,
      maxAutoOrderLimitDaily: _toDouble(json['maxAutoOrderLimitDaily']),
      maxAutoOrderLimitPerOrder: _toDouble(json['maxAutoOrderLimitPerOrder']),
      dataSharingConsent: json['dataSharingConsent'] == true,
      marketingConsent: json['marketingConsent'] == true,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'allergies': allergies.map((e) => e.toJson()).toList(),
        'favoriteFoods': favoriteFoods,
        'dislikedFoods': dislikedFoods,
        'agentPersona': agentPersona,
        'motivationStyle': motivationStyle,
        'autoOrderEnabled': autoOrderEnabled,
        'maxAutoOrderLimitDaily': maxAutoOrderLimitDaily,
        'maxAutoOrderLimitPerOrder': maxAutoOrderLimitPerOrder,
        'dataSharingConsent': dataSharingConsent,
        'marketingConsent': marketingConsent,
      };

  AccountPreferences copyWith({
    List<AllergyItem>? allergies,
    List<String>? favoriteFoods,
    List<String>? dislikedFoods,
    String? agentPersona,
    String? motivationStyle,
    bool? autoOrderEnabled,
    double? maxAutoOrderLimitDaily,
    double? maxAutoOrderLimitPerOrder,
    bool? dataSharingConsent,
    bool? marketingConsent,
  }) {
    return AccountPreferences(
      isConfigured: isConfigured,
      allergies: allergies ?? this.allergies,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      agentPersona: agentPersona ?? this.agentPersona,
      motivationStyle: motivationStyle ?? this.motivationStyle,
      autoOrderEnabled: autoOrderEnabled ?? this.autoOrderEnabled,
      maxAutoOrderLimitDaily: maxAutoOrderLimitDaily ?? this.maxAutoOrderLimitDaily,
      maxAutoOrderLimitPerOrder: maxAutoOrderLimitPerOrder ?? this.maxAutoOrderLimitPerOrder,
      dataSharingConsent: dataSharingConsent ?? this.dataSharingConsent,
      marketingConsent: marketingConsent ?? this.marketingConsent,
    );
  }
}

class BiometricProfileDetail {
  BiometricProfileDetail({
    required this.userId,
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
    required this.currentWeightKg,
    required this.targetWeightKg,
    this.currentBodyFatPercentage,
    this.goalBodyFatPercentage,
    this.muscleMassKg,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.fitnessExperienceLevel,
    required this.workoutLocationPreference,
    required this.baseTdee,
    required this.bmr,
    this.dailyProteinTargetGram,
    this.dailyCarbTargetGram,
    this.dailyFatTargetGram,
    this.injuries = const [],
    this.medications = const [],
  });

  final String userId;
  final String gender;
  final String dateOfBirth;
  final double heightCm;
  final double currentWeightKg;
  final double targetWeightKg;
  final double? currentBodyFatPercentage;
  final double? goalBodyFatPercentage;
  final double? muscleMassKg;
  final String fitnessGoal;
  final String activityLevel;
  final String fitnessExperienceLevel;
  final String workoutLocationPreference;
  final int baseTdee;
  final int bmr;
  final int? dailyProteinTargetGram;
  final int? dailyCarbTargetGram;
  final int? dailyFatTargetGram;
  final List<String> injuries;
  final List<String> medications;

  factory BiometricProfileDetail.fromJson(Map<String, dynamic> json) {
    return BiometricProfileDetail(
      userId: json['userId']?.toString() ?? '',
      gender: (json['gender'] ?? '').toString(),
      dateOfBirth: (json['dateOfBirth'] ?? '').toString(),
      heightCm: _toDouble(json['heightCm']) ?? 0,
      currentWeightKg: _toDouble(json['currentWeightKg']) ?? 0,
      targetWeightKg: _toDouble(json['targetWeightKg']) ?? 0,
      currentBodyFatPercentage: _toDouble(json['currentBodyFatPercentage']),
      goalBodyFatPercentage: _toDouble(json['goalBodyFatPercentage']),
      muscleMassKg: _toDouble(json['muscleMassKg']),
      fitnessGoal: (json['fitnessGoal'] ?? '').toString(),
      activityLevel: (json['activityLevel'] ?? '').toString(),
      fitnessExperienceLevel: (json['fitnessExperienceLevel'] ?? '').toString(),
      workoutLocationPreference: (json['workoutLocationPreference'] ?? '').toString(),
      baseTdee: _toInt(json['baseTDEE'] ?? json['baseTdee']) ?? 0,
      bmr: _toInt(json['bmr'] ?? json['BMR']) ?? 0,
      dailyProteinTargetGram: _toInt(json['dailyProteinTargetGram']),
      dailyCarbTargetGram: _toInt(json['dailyCarbTargetGram']),
      dailyFatTargetGram: _toInt(json['dailyFatTargetGram']),
      injuries: _stringList(json['injuries']),
      medications: _stringList(json['medications']),
    );
  }

  FitnessProfile toFitnessProfile() => FitnessProfile(
        isConfigured: true,
        gender: gender,
        dateOfBirth: dateOfBirth,
        heightCm: heightCm,
        currentWeightKg: currentWeightKg,
        targetWeightKg: targetWeightKg,
        currentBodyFatPercentage: currentBodyFatPercentage,
        goalBodyFatPercentage: goalBodyFatPercentage,
        muscleMassKg: muscleMassKg,
        fitnessGoal: fitnessGoal,
        activityLevel: activityLevel,
        fitnessExperienceLevel: fitnessExperienceLevel,
        workoutLocationPreference: workoutLocationPreference,
        baseTdee: baseTdee,
        bmr: bmr,
        dailyProteinTargetGram: dailyProteinTargetGram,
        dailyCarbTargetGram: dailyCarbTargetGram,
        dailyFatTargetGram: dailyFatTargetGram,
        injuries: injuries,
        medications: medications,
      );
}

class PublicProfile {
  PublicProfile({
    required this.userId,
    required this.fullName,
    this.avatarUrl,
    required this.currentLevel,
    required this.currentXp,
    required this.currentStreak,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final int currentLevel;
  final int currentXp;
  final int currentStreak;

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      userId: json['userId']?.toString() ?? '',
      fullName: (json['fullName'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      currentLevel: _jsonInt(json['currentLevel'], fallback: 1),
      currentXp: _jsonInt(json['currentXP'] ?? json['currentXp']),
      currentStreak: _jsonInt(json['currentStreak']),
    );
  }
}

int _jsonInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

class GamificationSummary {
  GamificationSummary({
    required this.currentLevel,
    required this.currentXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.syncCoins,
    required this.achievementPoints,
    required this.consecutivePerfectDays,
  });

  final int currentLevel;
  final int currentXp;
  final int currentStreak;
  final int longestStreak;
  final double syncCoins;
  final int achievementPoints;
  final int consecutivePerfectDays;

  factory GamificationSummary.fromJson(Map<String, dynamic> json) {
    return GamificationSummary(
      currentLevel: (json['currentLevel'] ?? 1) as int,
      currentXp: (json['currentXP'] ?? json['currentXp'] ?? 0) as int,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      longestStreak: (json['longestStreak'] ?? 0) as int,
      syncCoins: _toDouble(json['syncCoins']) ?? 0,
      achievementPoints: (json['achievementPoints'] ?? 0) as int,
      consecutivePerfectDays: (json['consecutivePerfectDays'] ?? 0) as int,
    );
  }
}

class VoucherItem {
  VoucherItem({
    required this.id,
    required this.voucherCode,
    required this.name,
    required this.promotionType,
    required this.value,
    required this.status,
    required this.acquiredAt,
    this.usedAt,
    this.validUntil,
    required this.isExpired,
  });

  final String id;
  final String voucherCode;
  final String name;
  final String promotionType;
  final double value;
  final String status;
  final String acquiredAt;
  final String? usedAt;
  final String? validUntil;
  final bool isExpired;

  factory VoucherItem.fromJson(Map<String, dynamic> json) {
    return VoucherItem(
      id: json['id']?.toString() ?? '',
      voucherCode: (json['voucherCode'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      promotionType: (json['promotionType'] ?? '').toString(),
      value: _toDouble(json['value']) ?? 0,
      status: (json['status'] ?? '').toString(),
      acquiredAt: (json['acquiredAt'] ?? '').toString(),
      usedAt: json['usedAt']?.toString(),
      validUntil: json['validUntil']?.toString(),
      isExpired: json['isExpired'] == true,
    );
  }
}

class AchievementItem {
  AchievementItem({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.xpReward,
    required this.coinReward,
    required this.iconUrl,
    required this.unlockedAt,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final int xpReward;
  final int coinReward;
  final String iconUrl;
  final String unlockedAt;

  factory AchievementItem.fromJson(Map<String, dynamic> json) {
    return AchievementItem(
      id: json['id']?.toString() ?? '',
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      xpReward: (json['xpReward'] ?? json['XPReward'] ?? 0) as int,
      coinReward: (json['coinReward'] ?? json['CoinReward'] ?? 0) as int,
      iconUrl: (json['iconUrl'] ?? '').toString(),
      unlockedAt: (json['unlockedAt'] ?? '').toString(),
    );
  }
}

class UserInventory {
  UserInventory({
    this.gamification,
    this.vouchers = const [],
    this.achievements = const [],
    required this.totalVouchers,
    required this.totalAchievementsUnlocked,
  });

  final GamificationSummary? gamification;
  final List<VoucherItem> vouchers;
  final List<AchievementItem> achievements;
  final int totalVouchers;
  final int totalAchievementsUnlocked;

  factory UserInventory.fromJson(Map<String, dynamic> json) {
    final g = json['gamification'];
    return UserInventory(
      gamification: g is Map<String, dynamic> ? GamificationSummary.fromJson(g) : null,
      vouchers: (json['vouchers'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(VoucherItem.fromJson)
          .toList(),
      achievements: (json['achievements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AchievementItem.fromJson)
          .toList(),
      totalVouchers: (json['totalVouchers'] ?? 0) as int,
      totalAchievementsUnlocked: (json['totalAchievementsUnlocked'] ?? 0) as int,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return [];
  return value.map((e) => e.toString()).toList();
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
