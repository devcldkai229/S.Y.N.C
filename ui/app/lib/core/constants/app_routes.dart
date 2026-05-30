class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const workouts = '/workouts';
  static const social = '/social';
  static const profile = '/profile';
  static const notifications = '/notifications';

  static const achievements = '/achievements';
  static const shop = '/shop';
  static const subscription = '/subscription';

  static String socialUserProfile(String userId) => '/social/user/$userId';

  static String exerciseDetail(String exerciseId) => '/workouts/exercise/$exerciseId';
}
