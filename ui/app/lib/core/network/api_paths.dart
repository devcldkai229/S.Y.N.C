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

  // Notification (gateway: /api/v1/notifications → Notification service :5106)
  static const notificationsMe = '/v1/notifications/me';
  static const notificationsMeUnreadCount = '/v1/notifications/me/unread-count';
  static const notificationsMeReadAll = '/v1/notifications/me/read-all';
  static String notificationMarkReadMe(String notificationId) =>
      '/v1/notifications/me/$notificationId/read';

  // Payment  (gateway prefix /v1/payment → service /v1, service routes use /api/v1/payments/...)
  static const subscriptionPlans = '/v1/payment/payments/subscription-plans';
  static const myActiveSubscription = '/v1/payment/payments/user-subscriptions/me/active';
  static const payosCreateLink = '/v1/payment/payments/payos/create-link';

  // IAM – gamification / shop
  static const meActivityLog = '/v1/iam/me/activity/log';
  static const meShop = '/v1/iam/me/shop';
  static const meShopPurchase = '/v1/iam/me/shop/purchase';

  // Social service (via Gateway :5057 → Social :5120)
  static const socialPosts = '/v1/posts';
  static const socialStories = '/v1/social/stories';
  static const socialStoriesFeed = '/v1/social/stories/feed';
  static const socialStoriesMe = '/v1/social/stories/me';
  static String socialCommentReplies(String commentId) =>
      '/v1/comments/$commentId/replies';

  // Community challenges (Social via Gateway)
  static const challenges = '/v1/challenges';
  static String challengeById(String id) => '/v1/challenges/$id';
  static String challengeJoin(String id) => '/v1/challenges/$id/join';
  static String challengeLeave(String id) => '/v1/challenges/$id/leave';
  static String challengeParticipationStatus(String id) =>
      '/v1/challenges/$id/participation-status';
  static String challengeRoute(String id) => '/v1/challenges/$id/route';

  // Social — user follow graph
  static String socialUserFollowCounts(String userId) =>
      '/v1/social/users/$userId/follow-counts';
  static String socialUserFollowStatus(String userId) =>
      '/v1/social/users/$userId/follow-status';
  static String socialUserFollow(String userId) => '/v1/social/users/$userId/follow';

  // Nutrition (gateway → /api/v1/nutrition/*)
  static const nutritionFoods = '/v1/nutrition/foods';
  static String nutritionFoodById(String id) => '/v1/nutrition/foods/$id';
  static String nutritionFoodByBarcode(String barcode) =>
      '/v1/nutrition/foods/barcode/$barcode';
  static const nutritionMealLogs = '/v1/nutrition/meal-logs';
  static String nutritionMealLogById(String id) => '/v1/nutrition/meal-logs/$id';
  static const nutritionDailySummary = '/v1/nutrition/daily-summary';
  static const nutritionDailySummaryWater = '/v1/nutrition/daily-summary/water';

  // Marketplace
  static const marketplacePartners = '/v1/marketplace/partners';
  static String marketplacePartnerById(String id) => '/v1/marketplace/partners/$id';
  static const marketplaceFoodMenu = '/v1/marketplace/food-menu-items';
  static String marketplaceFoodMenuById(String id) =>
      '/v1/marketplace/food-menu-items/$id';
  static const marketplaceAffiliateProducts = '/v1/marketplace/affiliate-products';
  static String marketplaceAffiliateProductById(String id) =>
      '/v1/marketplace/affiliate-products/$id';
  static String marketplaceAffiliateClick(String id) =>
      '/v1/marketplace/affiliate-products/$id/click';
  static const marketplaceReviews = '/v1/marketplace/reviews';

  // Order
  static const orderOrders = '/v1/order/orders';
  static String orderById(String id) => '/v1/order/orders/$id';
  static String orderTracking(String id) => '/v1/order/orders/$id/tracking';
  static String orderCancel(String id) => '/v1/order/orders/$id/cancel';
}
