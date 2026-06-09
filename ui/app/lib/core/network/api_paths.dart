/// Paths relative to [AppConfig.baseUrl] (e.g. `http://localhost:8080/api` + `/v1/auth/login`).
abstract final class ApiPaths {
  // Auth (direct)
  static const authLogin = '/v1/auth/login';
  static const authRegister = '/v1/auth/register';
  static const authInitRegistration = '/v1/auth/init-registration';
  static const authCompleteRegistration = '/v1/auth/complete-registration';
  static const authFinishRegistration = '/v1/auth/finish-registration';
  static const authResendVerification = '/v1/auth/resend-verification';
  static const authGoogle = '/v1/auth/google';
  static const authVerifyEmail = '/v1/auth/verify-email';
  static const authForgotPassword = '/v1/auth/forgot-password';
  static const authResetPassword = '/v1/auth/reset-password';

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
  static const onboardingComposition =
      '/v1/iam/biometrics/onboarding/composition';
  static const onboardingSafeguards =
      '/v1/iam/biometrics/onboarding/safeguards';
  static const onboardingComplete = '/v1/iam/biometrics/onboarding/complete';

  // Exercise
  static const exercises = '/v1/exercise/exercises';
  static String exerciseDetail(String id) =>
      '/v1/exercise/exercises/$id/detail';

  // Roadmap
  static const roadmaps = '/v1/roadmap/roadmaps';
  static const sessions = '/v1/roadmap/sessions';
  static const recoveryProfiles = '/v1/roadmap/recovery-profiles';
  static const customWorkouts = '/v1/roadmap/workouts';
  static const scheduledWorkouts = '/v1/roadmap/scheduled-workouts';
  static String sessionsByRoadmap(String roadmapId) =>
      '/v1/roadmap/sessions/roadmap/$roadmapId';
  static const workoutExecutions = '/v1/roadmap/workout-executions';
  static const exerciseSetLogs = '/v1/roadmap/exercise-set-logs';

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

  // Payment  (gateway prefix /v1/payment → service /v1, service routes use /api/v1/payments/...)
  static const subscriptionPlans = '/v1/payment/payments/subscription-plans';
  static const myActiveSubscription = '/v1/payment/payments/user-subscriptions/me/active';
  static const payosCreateLink = '/v1/payment/payments/payos/create-link';

  // IAM – gamification / shop
  static const meActivityLog = '/v1/iam/me/activity/log';
  static const meShop = '/v1/iam/me/shop';
  static const meShopPurchase = '/v1/iam/me/shop/purchase';

  // Social (future service)
  static const socialPosts = '/v1/social/posts';

  // Payment / Subscription
  static const subscriptionPlans        = '/v1/payment/subscription-plans';
  static const myActiveSubscription     = '/v1/payment/user-subscriptions/me/active';
  static const cancelMySubscription     = '/v1/payment/user-subscriptions/me/cancel';
  static const payosCreateLink          = '/v1/payment/payos/create-link';
  static String transactionByOrderCode(int orderCode) =>
      '/v1/payment/transactions/by-order-code/$orderCode';
}
