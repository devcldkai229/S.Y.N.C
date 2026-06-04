import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/auth/screens/login_screen.dart';
import 'package:sync_app/features/auth/screens/register_step1_screen.dart';
import 'package:sync_app/features/auth/screens/verify_email_screen.dart';
import 'package:sync_app/features/home/screens/home_screen.dart';
import 'package:sync_app/features/achievements/screens/achievements_screen.dart';
import 'package:sync_app/features/shop/screens/shop_screen.dart';
import 'package:sync_app/features/subscription/screens/subscription_screen.dart';
import 'package:sync_app/features/notifications/screens/notifications_screen.dart';
import 'package:sync_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:sync_app/features/profile/screens/profile_screen.dart';
import 'package:sync_app/features/social/screens/social_other_user_profile_screen.dart';
import 'package:sync_app/features/social/screens/social_screen.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/screens/create_custom_workout_screen.dart';
import 'package:sync_app/features/workouts/screens/custom_workout_detail_screen.dart';
import 'package:sync_app/features/workouts/screens/custom_session_detail_screen.dart';
import 'package:sync_app/features/workouts/screens/exercise_detail_screen.dart';
import 'package:sync_app/features/workouts/screens/workouts_screen.dart';
import 'package:sync_app/features/workouts/screens/workout_execution_screen.dart';
import 'package:sync_app/shared/widgets/main_shell_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.login,
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterStep1Screen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return VerifyEmailScreen(initialToken: token);
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.workouts,
                builder: (context, state) => const WorkoutsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.social,
                builder: (context, state) => const SocialScreen(),
                routes: [
                  GoRoute(
                    path: 'user/:userId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final userId = state.pathParameters['userId']!;
                      return SocialOtherUserProfileScreen(userId: userId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
GoRoute(
  path: AppRoutes.achievements,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const AchievementsScreen(),
),
GoRoute(
  path: AppRoutes.shop,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const ShopScreen(),
),
GoRoute(
  path: AppRoutes.subscription,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const SubscriptionScreen(),
),
GoRoute(
  path: AppRoutes.createCustomWorkout,
  parentNavigatorKey: rootNavigatorKey,
  builder: (context, state) => const CreateCustomWorkoutScreen(),
      ),
      GoRoute(
        path: '/workouts/custom/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomWorkoutDetailScreen(workoutId: id);
        },
      ),
      GoRoute(
        path: '/workouts/session/:sessionId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return CustomSessionDetailScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/workouts/session/:sessionId/active',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final session = state.extra as RoadmapSession?;
          return WorkoutExecutionScreen(
            sessionId: sessionId,
            initialSession: session,
          );
        },
GoRoute(
  path: '/workouts/exercise/:exerciseId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final exerciseId = state.pathParameters['exerciseId']!;
          final preview = state.extra;
          return ExerciseDetailScreen(
            exerciseId: exerciseId,
            preview: preview is ExerciseCatalogItem ? preview : null,
          );
        },
      ),
    ],
  );
}
