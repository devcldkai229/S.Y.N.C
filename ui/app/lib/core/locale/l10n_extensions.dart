import 'package:flutter/widgets.dart';
import 'package:sync_app/l10n/app_localizations.dart';
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized labels for backend enum codes.
abstract final class L10nEnums {
  static String fitnessGoal(AppLocalizations l10n, String? key) => switch (key) {
        'LoseFat' => l10n.fitnessGoalLoseFat,
        'BuildMuscle' => l10n.fitnessGoalBuildMuscle,
        'Maintain' => l10n.fitnessGoalMaintain,
        'Recomposition' => l10n.fitnessGoalRecomposition,
        'ImproveEndurance' => l10n.fitnessGoalEndurance,
        'GeneralHealth' => l10n.fitnessGoalGeneralHealth,
        _ => key ?? l10n.notSet,
      };

  static String activityLevel(AppLocalizations l10n, String? key) => switch (key) {
        'Sedentary' => l10n.activitySedentary,
        'LightlyActive' => l10n.activityLightlyActive,
        'ModeratelyActive' => l10n.activityModeratelyActive,
        'VeryActive' => l10n.activityVeryActive,
        'Athlete' => l10n.activityAthlete,
        _ => key ?? l10n.notSet,
      };

  static String experience(AppLocalizations l10n, String? key) => switch (key) {
        'Beginner' => l10n.experienceBeginner,
        'Intermediate' => l10n.experienceIntermediate,
        'Advanced' => l10n.experienceAdvanced,
        _ => key ?? l10n.notSet,
      };

  static String workoutLocation(AppLocalizations l10n, String? key) => switch (key) {
        'Home' => l10n.locationHome,
        'Gym' => l10n.locationGym,
        'Outdoor' => l10n.locationOutdoor,
        'Hybrid' => l10n.locationHybrid,
        _ => key ?? l10n.notSet,
      };

  static String agentPersona(AppLocalizations l10n, String? key) => switch (key) {
        'StrictCoach' => l10n.personaStrictCoach,
        'FriendlyBuddy' => l10n.personaFriendlyBuddy,
        'CalmMentor' => l10n.personaCalmMentor,
        'EnergeticTrainer' => l10n.personaEnergeticTrainer,
        _ => key ?? l10n.notSet,
      };

  static String motivationStyle(AppLocalizations l10n, String? key) => switch (key) {
        'Supportive' => l10n.motivationSupportive,
        'Aggressive' => l10n.motivationAggressive,
        'DisciplineFocused' => l10n.motivationDiscipline,
        'Friendly' => l10n.motivationFriendly,
        'Competitive' => l10n.motivationCompetitive,
        'Minimal' => l10n.motivationMinimal,
        _ => key ?? l10n.notSet,
      };

  static String gender(AppLocalizations l10n, String? key) => switch (key) {
        'Male' => l10n.genderMale,
        'Female' => l10n.genderFemale,
        'Other' => l10n.genderOther,
        _ => key ?? l10n.notSet,
      };

  static Map<String, String> fitnessGoalOptions(AppLocalizations l10n) => {
        'LoseFat': l10n.fitnessGoalLoseFat,
        'BuildMuscle': l10n.fitnessGoalBuildMuscle,
        'Maintain': l10n.fitnessGoalMaintain,
      };

  static Map<String, String> activityOptions(AppLocalizations l10n) => {
        'Sedentary': l10n.activitySedentary,
        'LightlyActive': l10n.activityLightlyActive,
        'ModeratelyActive': l10n.activityModeratelyActive,
        'VeryActive': l10n.activityVeryActive,
        'Athlete': l10n.activityAthlete,
      };

  static Map<String, String> genderOptions(AppLocalizations l10n) => {
        'Male': l10n.genderMale,
        'Female': l10n.genderFemale,
        'Other': l10n.genderOther,
      };

  static Map<String, String> experienceOptions(AppLocalizations l10n) => {
        'Beginner': l10n.experienceBeginner,
        'Intermediate': l10n.experienceIntermediate,
        'Advanced': l10n.experienceAdvanced,
      };

  static Map<String, String> locationOptions(AppLocalizations l10n) => {
        'Home': l10n.locationHome,
        'Gym': l10n.locationGym,
        'Outdoor': l10n.locationOutdoor,
        'Hybrid': l10n.locationHybrid,
      };

  static Map<String, String> personaOptions(AppLocalizations l10n) => {
        'StrictCoach': l10n.personaStrictCoach,
        'FriendlyBuddy': l10n.personaFriendlyBuddy,
        'CalmMentor': l10n.personaCalmMentor,
        'EnergeticTrainer': l10n.personaEnergeticTrainer,
      };

  static Map<String, String> motivationOptions(AppLocalizations l10n) => {
        'Supportive': l10n.motivationSupportive,
        'Aggressive': l10n.motivationAggressive,
        'DisciplineFocused': l10n.motivationDiscipline,
        'Friendly': l10n.motivationFriendly,
        'Competitive': l10n.motivationCompetitive,
        'Minimal': l10n.motivationMinimal,
      };
}
