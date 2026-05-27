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
    this.fitnessGoal,
    this.activityLevel,
    this.fitnessExperienceLevel,
  });

  final bool isConfigured;
  final String? gender;
  final String? dateOfBirth;
  final double? heightCm;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final String? fitnessGoal;
  final String? activityLevel;
  final String? fitnessExperienceLevel;

  factory FitnessProfile.fromJson(Map<String, dynamic> json) {
    return FitnessProfile(
      isConfigured: json['isConfigured'] == true,
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      heightCm: _toDouble(json['heightCm']),
      currentWeightKg: _toDouble(json['currentWeightKg']),
      targetWeightKg: _toDouble(json['targetWeightKg']),
      fitnessGoal: json['fitnessGoal']?.toString(),
      activityLevel: json['activityLevel']?.toString(),
      fitnessExperienceLevel: json['fitnessExperienceLevel']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'heightCm': heightCm,
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'fitnessGoal': fitnessGoal,
        'activityLevel': activityLevel,
        'fitnessExperienceLevel': fitnessExperienceLevel,
      };
}

class AccountPreferences {
  AccountPreferences({
    required this.isConfigured,
    required this.agentPersona,
    required this.motivationStyle,
    required this.dataSharingConsent,
    required this.marketingConsent,
  });

  final bool isConfigured;
  final String agentPersona;
  final String motivationStyle;
  final bool dataSharingConsent;
  final bool marketingConsent;

  factory AccountPreferences.fromJson(Map<String, dynamic> json) {
    return AccountPreferences(
      isConfigured: json['isConfigured'] == true,
      agentPersona: (json['agentPersona'] ?? '').toString(),
      motivationStyle: (json['motivationStyle'] ?? '').toString(),
      dataSharingConsent: json['dataSharingConsent'] == true,
      marketingConsent: json['marketingConsent'] == true,
    );
  }
}

class GamificationSummary {
  GamificationSummary({
    required this.currentLevel,
    required this.currentXp,
    required this.currentStreak,
    required this.syncCoins,
    required this.achievementPoints,
  });

  final int currentLevel;
  final int currentXp;
  final int currentStreak;
  final double syncCoins;
  final int achievementPoints;

  factory GamificationSummary.fromJson(Map<String, dynamic> json) {
    return GamificationSummary(
      currentLevel: (json['currentLevel'] ?? 1) as int,
      currentXp: (json['currentXP'] ?? json['currentXp'] ?? 0) as int,
      currentStreak: (json['currentStreak'] ?? 0) as int,
      syncCoins: _toDouble(json['syncCoins']) ?? 0,
      achievementPoints: (json['achievementPoints'] ?? 0) as int,
    );
  }
}

class UserInventory {
  UserInventory({this.gamification, required this.totalAchievementsUnlocked});

  final GamificationSummary? gamification;
  final int totalAchievementsUnlocked;

  factory UserInventory.fromJson(Map<String, dynamic> json) {
    final g = json['gamification'];
    return UserInventory(
      gamification: g is Map<String, dynamic> ? GamificationSummary.fromJson(g) : null,
      totalAchievementsUnlocked: (json['totalAchievementsUnlocked'] ?? 0) as int,
    );
  }
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
