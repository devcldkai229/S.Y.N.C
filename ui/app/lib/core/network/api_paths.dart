/// Paths relative to [AppConfig.baseUrl] (e.g. `http://localhost:8080/api` + `/v1/auth/login`).
abstract final class ApiPaths {
  // Auth (direct)
  static const authLogin = '/v1/auth/login';
  static const authRegister = '/v1/auth/register';
  static const authGoogle = '/v1/auth/google';
  static const authVerifyEmail = '/v1/auth/verify-email';

  // IAM (gateway prefix: /v1/iam → service /v1)
  static const meProfileSettings = '/v1/iam/me/profile-settings';
  static const meInventory = '/v1/iam/me/inventory';
  static const meBasicProfile = '/v1/iam/me/basic-profile';
  static const meFitnessProfile = '/v1/iam/me/fitness-profile';
  static const meAccountPreferences = '/v1/iam/me/account-preferences';
  static const biometrics = '/v1/iam/biometrics';
  static const biometricsLogWeight = '/v1/iam/biometrics/weight';
  static String userPublicProfile(String userId) =>
      '/v1/users/$userId/public-profile';
  static const onboardingBasic = '/v1/iam/biometrics/onboarding/basic';
  static const onboardingGoals = '/v1/iam/biometrics/onboarding/goals';
  static const onboardingComposition = '/v1/iam/biometrics/onboarding/composition';
  static const onboardingSafeguards = '/v1/iam/biometrics/onboarding/safeguards';
  static const onboardingComplete = '/v1/iam/biometrics/onboarding/complete';

  // Exercise
  static const exercises = '/v1/exercise/exercises';
  static String exerciseDetail(String id) => '/v1/exercise/exercises/$id/detail';

  // Roadmap
  static const roadmaps = '/v1/roadmap/roadmaps';
  static const sessions = '/v1/roadmap/sessions';
  static const recoveryProfiles = '/v1/roadmap/recovery-profiles';
  static const customWorkouts = '/v1/roadmap/workouts';
  static String sessionsByRoadmap(String roadmapId) =>
      '/v1/roadmap/sessions/roadmap/$roadmapId';

  // Notification
  static const notifications = '/v1/notification/notifications';
  static String notificationUserInbox(String userId) =>
      '$notifications/users/$userId';
  static String notificationUnreadCount(String userId) =>
      '$notifications/users/$userId/unread-count';
  static String notificationMarkRead(String userId, String notificationId) =>
      '$notifications/users/$userId/$notificationId/read';
  static String notificationMarkAllRead(String userId) =>
      '$notifications/users/$userId/read-all';

  // Social (future service)
  static const socialPosts = '/v1/social/posts';
}
