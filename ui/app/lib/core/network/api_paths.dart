/// Paths relative to [AppConfig.baseUrl] (e.g. `http://localhost:8080/api` + `/v1/auth/login`).
abstract final class ApiPaths {
  // Auth (direct)
  static const authLogin = '/v1/auth/login';
  static const authRegister = '/v1/auth/register';
  static const authGoogle = '/v1/auth/google';

  // IAM (gateway prefix: /v1/iam → service /v1)
  static const meProfileSettings = '/v1/iam/me/profile-settings';
  static const meInventory = '/v1/iam/me/inventory';
  static const meBasicProfile = '/v1/iam/me/basic-profile';
  static const meFitnessProfile = '/v1/iam/me/fitness-profile';
  static const meAccountPreferences = '/v1/iam/me/account-preferences';
  static const biometrics = '/v1/iam/biometrics';
  static const onboardingBasic = '/v1/iam/biometrics/onboarding/basic';
  static const onboardingGoals = '/v1/iam/biometrics/onboarding/goals';
  static const onboardingComposition = '/v1/iam/biometrics/onboarding/composition';
  static const onboardingSafeguards = '/v1/iam/biometrics/onboarding/safeguards';

  // Exercise
  static const exercises = '/v1/exercise/exercises';
  static String exerciseDetail(String id) => '/v1/exercise/exercises/$id/detail';

  // Roadmap
  static const roadmaps = '/v1/roadmap/roadmaps';
  static const sessions = '/v1/roadmap/sessions';
  static const recoveryProfiles = '/v1/roadmap/recovery-profiles';

  // Notification
  static const notifications = '/v1/notification/notifications';

  // Social (future service)
  static const socialPosts = '/v1/social/posts';
}
