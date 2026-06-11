class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const workouts = '/workouts';
  static const social = '/social';
  static const profile = '/profile';
  static const notifications = '/notifications';
  static const cynChat = '/cyn';

  static const achievements = '/achievements';
  static const shop = '/shop';
  static const subscription = '/subscription';
  static const challengesMap = '/challenges';

  static String challengeDetail(String id) => '/challenges/$id';

  static String challengeRoute(String id) => '/challenges/$id/route';
  static const createCustomWorkout = '/workouts/custom/create';

  static String socialUserProfile(String userId) => '/social/user/$userId';

  static const socialSearch = '/social/search';

  static String exerciseDetail(String exerciseId) => '/workouts/exercise/$exerciseId';

  static String customWorkoutDetail(String id) => '/workouts/custom/$id';

  static String customSessionDetail(String sessionId) => '/workouts/session/$sessionId';

  static String activeWorkout(String sessionId) => '/workouts/session/$sessionId/active';

  // Nutrition
  static const nutritionDiary = '/nutrition';
  static const nutritionFoodSearch = '/nutrition/search';
  static const nutritionCreateFood = '/nutrition/create-food';

  // Marketplace
  static const marketplaceHome = '/marketplace';
  static String marketplacePartner(String id) => '/marketplace/partner/$id';
  static String marketplaceFoodItem(String id) => '/marketplace/food/$id';
  static String marketplaceAffiliate(String id) => '/marketplace/affiliate/$id';
  static const marketplaceWriteReview = '/marketplace/review';

  // Order
  static const orderCart = '/order/cart';
  static const orderCheckout = '/order/checkout';
  static const orderSuccess = '/order/success';
  static const orderList = '/orders';
  static String orderDetail(String id) => '/orders/$id';
  static String orderTracking(String id) => '/orders/$id/tracking';
}
