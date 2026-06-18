class OnboardingStep1Request {
  OnboardingStep1Request({
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
  });

  final String gender;
  final String dateOfBirth;
  final double heightCm;

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'heightCm': heightCm,
      };
}

class OnboardingStep2Request {
  OnboardingStep2Request({
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.fitnessGoal,
    required this.activityLevel,
    required this.fitnessExperienceLevel,
    required this.workoutLocationPreference,
  });

  final double currentWeightKg;
  final double targetWeightKg;
  final String fitnessGoal;
  final String activityLevel;
  final String fitnessExperienceLevel;
  final String workoutLocationPreference;

  Map<String, dynamic> toJson() => {
        'currentWeightKg': currentWeightKg,
        'targetWeightKg': targetWeightKg,
        'fitnessGoal': fitnessGoal,
        'activityLevel': activityLevel,
        'fitnessExperienceLevel': fitnessExperienceLevel,
        'workoutLocationPreference': workoutLocationPreference,
      };
}

class OnboardingStep3Request {
  OnboardingStep3Request({
    this.currentBodyFatPercentage,
    this.goalBodyFatPercentage,
    this.muscleMassKg,
  });

  final double? currentBodyFatPercentage;
  final double? goalBodyFatPercentage;
  final double? muscleMassKg;

  Map<String, dynamic> toJson() => {
        'currentBodyFatPercentage': currentBodyFatPercentage,
        'goalBodyFatPercentage': goalBodyFatPercentage,
        'muscleMassKg': muscleMassKg,
      };
}

class OnboardingStep4Request {
  OnboardingStep4Request({this.injuries, this.medications});

  final List<String>? injuries;
  final List<String>? medications;

  Map<String, dynamic> toJson() => {
        'injuries': injuries ?? [],
        'medications': medications ?? [],
      };
}

class OnboardingAccountPreferencesRequest {
  OnboardingAccountPreferencesRequest({
    required this.allergies,
    this.favoriteFoods = const [],
    this.dislikedFoods = const [],
    required this.agentPersona,
    required this.motivationStyle,
    required this.dataSharingConsent,
    required this.marketingConsent,
  });

  final List<String> allergies;
  final List<String> favoriteFoods;
  final List<String> dislikedFoods;
  final String agentPersona;
  final String motivationStyle;
  final bool dataSharingConsent;
  final bool marketingConsent;

  Map<String, dynamic> toJson() => {
        'allergies': allergies
            .map((name) => <String, dynamic>{'allergenName': name})
            .toList(),
        'favoriteFoods': favoriteFoods,
        'dislikedFoods': dislikedFoods,
        'agentPersona': agentPersona,
        'motivationStyle': motivationStyle,
        'dataSharingConsent': dataSharingConsent,
        'marketingConsent': marketingConsent,
      };
}
