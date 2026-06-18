import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navWorkouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get navWorkouts;

  /// No description provided for @navSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get navSocial;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionFinishSetup.
  ///
  /// In en, this message translates to:
  /// **'Finish setup'**
  String get actionFinishSetup;

  /// No description provided for @savedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get savedSuccessfully;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @quickActionsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Quick actions — coming soon'**
  String get quickActionsComingSoon;

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get languageVietnamese;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'HIGH PERFORMANCE TRAINING'**
  String get loginTagline;

  /// No description provided for @loginWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue your training journey'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @googleSignIn.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get googleSignIn;

  /// No description provided for @noAccountRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccountRegister;

  /// No description provided for @verifyEmailLink.
  ///
  /// In en, this message translates to:
  /// **'Verify email with token'**
  String get verifyEmailLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join SYNC and start your plan'**
  String get registerSubtitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @hasAccountLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get hasAccountLogin;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Paste the token from your email or IAM dev log'**
  String get verifyEmailHint;

  /// No description provided for @verifyEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyEmailButton;

  /// No description provided for @onboardingSideATitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness profile'**
  String get onboardingSideATitle;

  /// No description provided for @onboardingSideASubtitle.
  ///
  /// In en, this message translates to:
  /// **'Biometrics help calculate calories and your training plan.'**
  String get onboardingSideASubtitle;

  /// No description provided for @onboardingSideBTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences & AI Coach'**
  String get onboardingSideBTitle;

  /// No description provided for @onboardingSideBSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help nutrition and coaching fit your lifestyle.'**
  String get onboardingSideBSubtitle;

  /// No description provided for @genderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderLabel;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @dateOfBirthLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirthLabel;

  /// No description provided for @heightCmLabel.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get heightCmLabel;

  /// No description provided for @currentWeightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Current weight (kg)'**
  String get currentWeightKgLabel;

  /// No description provided for @targetWeightKgLabel.
  ///
  /// In en, this message translates to:
  /// **'Target weight (kg)'**
  String get targetWeightKgLabel;

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goalLabel;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get activityLabel;

  /// No description provided for @experienceLabel.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experienceLabel;

  /// No description provided for @trainingLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Training location'**
  String get trainingLocationLabel;

  /// No description provided for @injuriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Injuries / conditions (if any)'**
  String get injuriesLabel;

  /// No description provided for @injuriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search injuries, e.g. neck pain, lower back…'**
  String get injuriesSearchHint;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies / intolerances'**
  String get allergiesLabel;

  /// No description provided for @allergiesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search allergies, e.g. peanut, seafood…'**
  String get allergiesSearchHint;

  /// No description provided for @favoriteFoodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite foods (optional)'**
  String get favoriteFoodsLabel;

  /// No description provided for @favoriteFoodsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search dishes, e.g. pho, rice plate…'**
  String get favoriteFoodsSearchHint;

  /// No description provided for @dislikedFoodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Disliked foods (optional)'**
  String get dislikedFoodsLabel;

  /// No description provided for @dislikedFoodsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search dishes, e.g. cilantro, shrimp paste…'**
  String get dislikedFoodsSearchHint;

  /// No description provided for @aiCoachStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Coach style'**
  String get aiCoachStyleLabel;

  /// No description provided for @motivationStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Motivation style'**
  String get motivationStyleLabel;

  /// No description provided for @consentDataSharing.
  ///
  /// In en, this message translates to:
  /// **'I agree to share health data for personalization'**
  String get consentDataSharing;

  /// No description provided for @consentMarketing.
  ///
  /// In en, this message translates to:
  /// **'I agree to receive promotions and health tips'**
  String get consentMarketing;

  /// No description provided for @onboardingValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get onboardingValidationRequired;

  /// No description provided for @onboardingValidationAllergies.
  ///
  /// In en, this message translates to:
  /// **'Select at least one allergy and accept required terms.'**
  String get onboardingValidationAllergies;

  /// No description provided for @fitnessGoalLoseFat.
  ///
  /// In en, this message translates to:
  /// **'Lose fat'**
  String get fitnessGoalLoseFat;

  /// No description provided for @fitnessGoalBuildMuscle.
  ///
  /// In en, this message translates to:
  /// **'Build muscle'**
  String get fitnessGoalBuildMuscle;

  /// No description provided for @fitnessGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get fitnessGoalMaintain;

  /// No description provided for @fitnessGoalRecomposition.
  ///
  /// In en, this message translates to:
  /// **'Recomposition'**
  String get fitnessGoalRecomposition;

  /// No description provided for @fitnessGoalEndurance.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get fitnessGoalEndurance;

  /// No description provided for @fitnessGoalGeneralHealth.
  ///
  /// In en, this message translates to:
  /// **'General health'**
  String get fitnessGoalGeneralHealth;

  /// No description provided for @activitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get activitySedentary;

  /// No description provided for @activityLightlyActive.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get activityLightlyActive;

  /// No description provided for @activityModeratelyActive.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get activityModeratelyActive;

  /// No description provided for @activityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get activityVeryActive;

  /// No description provided for @activityAthlete.
  ///
  /// In en, this message translates to:
  /// **'Athlete'**
  String get activityAthlete;

  /// No description provided for @experienceBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get experienceBeginner;

  /// No description provided for @experienceIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get experienceIntermediate;

  /// No description provided for @experienceAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get experienceAdvanced;

  /// No description provided for @locationHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get locationHome;

  /// No description provided for @locationGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get locationGym;

  /// No description provided for @locationOutdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor'**
  String get locationOutdoor;

  /// No description provided for @locationHybrid.
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get locationHybrid;

  /// No description provided for @personaStrictCoach.
  ///
  /// In en, this message translates to:
  /// **'Strict coach'**
  String get personaStrictCoach;

  /// No description provided for @personaFriendlyBuddy.
  ///
  /// In en, this message translates to:
  /// **'Friendly buddy'**
  String get personaFriendlyBuddy;

  /// No description provided for @personaCalmMentor.
  ///
  /// In en, this message translates to:
  /// **'Calm mentor'**
  String get personaCalmMentor;

  /// No description provided for @personaEnergeticTrainer.
  ///
  /// In en, this message translates to:
  /// **'Energetic trainer'**
  String get personaEnergeticTrainer;

  /// No description provided for @motivationSupportive.
  ///
  /// In en, this message translates to:
  /// **'Supportive'**
  String get motivationSupportive;

  /// No description provided for @motivationAggressive.
  ///
  /// In en, this message translates to:
  /// **'Push hard'**
  String get motivationAggressive;

  /// No description provided for @motivationDiscipline.
  ///
  /// In en, this message translates to:
  /// **'Discipline'**
  String get motivationDiscipline;

  /// No description provided for @motivationFriendly.
  ///
  /// In en, this message translates to:
  /// **'Friendly'**
  String get motivationFriendly;

  /// No description provided for @motivationCompetitive.
  ///
  /// In en, this message translates to:
  /// **'Competitive'**
  String get motivationCompetitive;

  /// No description provided for @motivationMinimal.
  ///
  /// In en, this message translates to:
  /// **'Minimal'**
  String get motivationMinimal;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSetupBanner.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile so AI can personalize workouts and nutrition.'**
  String get profileSetupBanner;

  /// No description provided for @profileCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Profile completeness'**
  String get profileCompleteness;

  /// No description provided for @sectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sectionAccount;

  /// No description provided for @sectionFitness.
  ///
  /// In en, this message translates to:
  /// **'Fitness & goals'**
  String get sectionFitness;

  /// No description provided for @sectionMacros.
  ///
  /// In en, this message translates to:
  /// **'Daily macros (AI calculated)'**
  String get sectionMacros;

  /// No description provided for @sectionNutritionAi.
  ///
  /// In en, this message translates to:
  /// **'Nutrition & AI Coach'**
  String get sectionNutritionAi;

  /// No description provided for @sectionGamification.
  ///
  /// In en, this message translates to:
  /// **'Gamification & rewards'**
  String get sectionGamification;

  /// No description provided for @sectionPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get sectionPublicProfile;

  /// No description provided for @fullSetupProfile.
  ///
  /// In en, this message translates to:
  /// **'Full profile setup'**
  String get fullSetupProfile;

  /// No description provided for @weightQuickAction.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightQuickAction;

  /// No description provided for @logWeightTitle.
  ///
  /// In en, this message translates to:
  /// **'Update weight'**
  String get logWeightTitle;

  /// No description provided for @logWeightSave.
  ///
  /// In en, this message translates to:
  /// **'Save & recalculate macros'**
  String get logWeightSave;

  /// No description provided for @fitnessNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Fitness profile not set up. Tap edit or use full setup.'**
  String get fitnessNotConfigured;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @timezone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timezone;

  /// No description provided for @packageTier.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get packageTier;

  /// No description provided for @emailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified'**
  String get emailVerified;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get notSet;

  /// No description provided for @bmrKcal.
  ///
  /// In en, this message translates to:
  /// **'BMR'**
  String get bmrKcal;

  /// No description provided for @tdeeKcal.
  ///
  /// In en, this message translates to:
  /// **'TDEE'**
  String get tdeeKcal;

  /// No description provided for @proteinG.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinG;

  /// No description provided for @carbG.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbG;

  /// No description provided for @fatG.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatG;

  /// No description provided for @allergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergies;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @disliked.
  ///
  /// In en, this message translates to:
  /// **'Disliked'**
  String get disliked;

  /// No description provided for @dataSharing.
  ///
  /// In en, this message translates to:
  /// **'Data sharing'**
  String get dataSharing;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @agreed.
  ///
  /// In en, this message translates to:
  /// **'Agreed'**
  String get agreed;

  /// No description provided for @notAgreed.
  ///
  /// In en, this message translates to:
  /// **'Not agreed'**
  String get notAgreed;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// No description provided for @streakDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String streakDays(int count);

  /// No description provided for @longestStreak.
  ///
  /// In en, this message translates to:
  /// **'longest {count}'**
  String longestStreak(int count);

  /// No description provided for @syncCoins.
  ///
  /// In en, this message translates to:
  /// **'Sync Coins'**
  String get syncCoins;

  /// No description provided for @achievementPoints.
  ///
  /// In en, this message translates to:
  /// **'Achievement points'**
  String get achievementPoints;

  /// No description provided for @achievementsUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Achievements unlocked'**
  String get achievementsUnlocked;

  /// No description provided for @vouchers.
  ///
  /// In en, this message translates to:
  /// **'Vouchers'**
  String get vouchers;

  /// No description provided for @recentAchievements.
  ///
  /// In en, this message translates to:
  /// **'Recent achievements'**
  String get recentAchievements;

  /// No description provided for @achievementXp.
  ///
  /// In en, this message translates to:
  /// **'• {name} (+{xp} XP)'**
  String achievementXp(String name, int xp);

  /// No description provided for @medicationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medicationsLabel;

  /// No description provided for @refreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTooltip;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTooltip;

  /// No description provided for @emailUnverifiedSuffix.
  ///
  /// In en, this message translates to:
  /// **' · Email not verified'**
  String get emailUnverifiedSuffix;

  /// No description provided for @dateOfBirthIsoHint.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (YYYY-MM-DD)'**
  String get dateOfBirthIsoHint;

  /// No description provided for @preferencesEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences & AI'**
  String get preferencesEditorTitle;

  /// No description provided for @fitnessEditorTitle.
  ///
  /// In en, this message translates to:
  /// **'Fitness profile'**
  String get fitnessEditorTitle;

  /// No description provided for @loadProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profile.'**
  String get loadProfileFailed;

  /// No description provided for @authErrorServer.
  ///
  /// In en, this message translates to:
  /// **'Server error (500). Check backend/IAM database migrations.'**
  String get authErrorServer;

  /// No description provided for @authErrorEmailNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Email not verified. Open the link in your email or use Verify email (token from IAM log when SMTP is off).'**
  String get authErrorEmailNotVerified;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered. Sign in or use another email.'**
  String get authErrorEmailExists;

  /// No description provided for @authErrorInvalidToken.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired verification token.'**
  String get authErrorInvalidToken;

  /// No description provided for @authErrorConnection.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach API ({url}). Start backend Gateway on :5057.'**
  String authErrorConnection(String url);

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication request failed.'**
  String get authErrorGeneric;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
