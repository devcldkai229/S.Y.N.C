import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/notifications/notification_inbox_notifier.dart';
import 'package:sync_app/core/notifications/notification_realtime_service.dart';
import 'package:sync_app/core/network/dio_client.dart';
import 'package:sync_app/data/datasources/notification_remote_data_source.dart';
import 'package:sync_app/data/datasources/onboarding_remote_data_source.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/data/repositories/challenge_repository.dart';
import 'package:sync_app/data/repositories/home_repository.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';
import 'package:sync_app/data/repositories/onboarding_repository.dart';
import 'package:sync_app/data/repositories/profile_repository.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/data/repositories/ai_workout_repository.dart';
import 'package:sync_app/features/workouts/services/ai_workout_api_service.dart';
import 'package:sync_app/features/challenges/data/challenge_remote_data_source.dart';
import 'package:sync_app/features/challenges/state/challenge_join_state.dart';
import 'package:sync_app/features/social/data/social_remote_data_source.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/subscription/services/subscription_api_service.dart';
import 'package:sync_app/features/workouts/services/workout_api_service.dart';
import 'package:sync_app/features/nutrition/data/nutrition_remote_data_source.dart';
import 'package:sync_app/features/nutrition/services/nutrition_realtime_service.dart';
import 'package:sync_app/features/nutrition/state/nutrition_refresh_notifier.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_repository.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_home_cubit.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/data/payment_remote_data_source.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/features/order/state/delivery_fee_config.dart';
import 'package:sync_app/features/order/data/order_demo_repository.dart';
import 'package:sync_app/features/order/services/websocket_tracking_service.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerLazySingleton(() => LocaleCubit(prefs));
  getIt.registerLazySingleton(() => const FlutterSecureStorage());
  getIt.registerLazySingleton(() => createDio(storage: getIt()));
  getIt.registerLazySingleton(() => AuthService(getIt(), getIt()));
  getIt.registerLazySingleton(() => ProfileApiService(getIt()));
  getIt.registerLazySingleton(() => SubscriptionApiService(getIt()));
  getIt.registerLazySingleton(() => WorkoutApiService(getIt()));
  getIt.registerLazySingleton(() => AiWorkoutApiService(getIt()));
  getIt.registerLazySingleton(() => NotificationRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => OnboardingRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => SocialRemoteDataSource(getIt()));

  getIt.registerLazySingleton(() => AuthRepository(getIt(), getIt()));
  getIt.registerLazySingleton(() => HomeRepository(getIt(), getIt()));
  getIt.registerLazySingleton(() => ProfileRepository(getIt()));
  getIt.registerLazySingleton(() => WorkoutRepository(getIt()));
  getIt.registerLazySingleton(() => AiWorkoutRepository(getIt()));
  getIt.registerLazySingleton(() => NotificationRepository(getIt()));
  getIt.registerLazySingleton(() => NotificationInboxNotifier());
  getIt.registerLazySingleton(() => NotificationRealtimeService(getIt(), getIt()));
  getIt.registerLazySingleton(() => OnboardingRepository(getIt()));
  getIt.registerLazySingleton(() => SocialRepository(getIt()));
  getIt.registerLazySingleton(() => ChallengeRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => ChallengeRepository(getIt()));
  getIt.registerLazySingleton(() => ChallengeJoinState(getIt()));
  getIt.registerLazySingleton(() => NutritionRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => NutritionRefreshNotifier());
  getIt.registerLazySingleton(() => NutritionRealtimeService(getIt(), getIt()));
  getIt.registerLazySingleton(() => MarketplaceRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => CheckoutRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => DeliveryFeeConfig(getIt()));
  getIt.registerLazySingleton<MarketplaceRepository>(
    () => MarketplaceRemoteRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton(() => OrderRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => PaymentRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => ActiveOrderCountNotifier(getIt()));
  getIt.registerLazySingleton(OrderDemoRepository.new);
  getIt.registerFactory<ITrackingService>(
    () => WebSocketTrackingService(getIt<AuthService>(), getIt()),
  );
  getIt.registerLazySingleton(() => MarketplaceCartCubit(getIt()));
  getIt.registerFactory(() => MarketplaceHomeCubit(getIt(), getIt()));
}
