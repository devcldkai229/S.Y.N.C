import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/app/router/app_router.dart';
import 'package:sync_app/core/config/app_config.dart';
import 'package:sync_app/core/theme/app_theme.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/data/repositories/home_repository.dart';
import 'package:sync_app/data/repositories/notification_repository.dart';
import 'package:sync_app/data/repositories/onboarding_repository.dart';
import 'package:sync_app/data/repositories/profile_repository.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const SyncApp());
}

class SyncApp extends StatelessWidget {
  const SyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: getIt<AuthRepository>()),
        RepositoryProvider.value(value: getIt<HomeRepository>()),
        RepositoryProvider.value(value: getIt<ProfileRepository>()),
        RepositoryProvider.value(value: getIt<WorkoutRepository>()),
        RepositoryProvider.value(value: getIt<NotificationRepository>()),
        RepositoryProvider.value(value: getIt<OnboardingRepository>()),
        RepositoryProvider.value(value: getIt<SocialRepository>()),
      ],
      child: MaterialApp.router(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
