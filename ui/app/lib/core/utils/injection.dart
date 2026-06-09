import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/network/dio_client.dart';
import 'package:sync_app/data/datasources/notification_remote_data_source.dart';
import 'package:sync_app/data/datasources/onboarding_remote_data_source.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/data/repositories/home_repository.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';
import 'package:sync_app/data/repositories/onboarding_repository.dart';
import 'package:sync_app/data/repositories/profile_repository.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/social/data/social_remote_data_source.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/subscription/services/subscription_api_service.dart';
import 'package:sync_app/features/workouts/services/workout_api_service.dart';

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
  getIt.registerLazySingleton(() => SubscriptionApiService(getIt()));
  getIt.registerLazySingleton(() => NotificationRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => OnboardingRemoteDataSource(getIt()));
  getIt.registerLazySingleton(() => SocialRemoteDataSource(getIt()));

  getIt.registerLazySingleton(() => AuthRepository(getIt(), getIt()));
  getIt.registerLazySingleton(() => HomeRepository(getIt(), getIt()));
  getIt.registerLazySingleton(() => ProfileRepository(getIt()));
  getIt.registerLazySingleton(() => WorkoutRepository(getIt()));
  getIt.registerLazySingleton(() => NotificationRepository(getIt()));
  getIt.registerLazySingleton(() => OnboardingRepository(getIt()));
  getIt.registerLazySingleton(() => SocialRepository(getIt()));
}
