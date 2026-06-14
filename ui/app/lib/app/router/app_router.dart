import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/auth/screens/login_screen.dart';
import 'package:sync_app/features/auth/screens/forgot_password_screen.dart';
import 'package:sync_app/features/auth/screens/register_step1_screen.dart';
import 'package:sync_app/features/home/screens/home_screen.dart';
import 'package:sync_app/features/achievements/screens/achievements_screen.dart';
import 'package:sync_app/features/shop/screens/shop_screen.dart';
import 'package:sync_app/features/subscription/screens/subscription_screen.dart';
import 'package:sync_app/features/notifications/screens/notifications_screen.dart';
import 'package:sync_app/features/onboarding/screens/onboarding_screen.dart';
import 'package:sync_app/features/profile/screens/profile_screen.dart';
import 'package:sync_app/features/social/screens/social_other_user_profile_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/screens/social_screen.dart';
import 'package:sync_app/features/social/screens/social_search_screen.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/screens/create_custom_workout_screen.dart';
import 'package:sync_app/features/workouts/screens/custom_workout_detail_screen.dart';
import 'package:sync_app/features/workouts/screens/custom_session_detail_screen.dart';
import 'package:sync_app/features/workouts/screens/exercise_detail_screen.dart';
import 'package:sync_app/features/challenges/models/challenge_models.dart';
import 'package:sync_app/features/challenges/screens/challenge_detail_screen.dart';
import 'package:sync_app/features/challenges/screens/challenges_map_screen.dart';
import 'package:sync_app/features/challenges/screens/route_map_screen.dart';
import 'package:sync_app/features/cyn/screens/cyn_chat_screen.dart';
import 'package:sync_app/features/workouts/screens/workouts_screen.dart';
import 'package:sync_app/features/workouts/screens/workout_execution_screen.dart';
import 'package:sync_app/shared/widgets/main_shell_scaffold.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';
import 'package:sync_app/features/nutrition/screens/nutrition_diary_screen.dart';
import 'package:sync_app/features/nutrition/screens/food_search_screen.dart';
import 'package:sync_app/features/nutrition/screens/create_food_screen.dart';
import 'package:sync_app/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:sync_app/features/marketplace/screens/marketplace_listing_screen.dart';
import 'package:sync_app/features/marketplace/screens/marketplace_search_screen.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/screens/nearby_kitchens_screen.dart';
import 'package:sync_app/features/marketplace/screens/partner_detail_screen.dart';
import 'package:sync_app/features/marketplace/screens/food_menu_item_detail_screen.dart';
import 'package:sync_app/features/marketplace/screens/affiliate_product_detail_screen.dart';
import 'package:sync_app/features/marketplace/screens/write_review_screen.dart';
import 'package:sync_app/features/order/screens/cart_screen.dart';
import 'package:sync_app/features/order/screens/checkout_screen.dart';
import 'package:sync_app/features/order/screens/order_success_screen.dart';
import 'package:sync_app/features/order/screens/order_list_screen.dart';
import 'package:sync_app/features/order/screens/order_detail_screen.dart';
import 'package:sync_app/features/order/screens/order_tracking_screen.dart';
import 'package:sync_app/features/order/models/order_models.dart';

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
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
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
                    path: 'search',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final cubit = state.extra as SocialCubit?;
                      return BlocProvider.value(
                        value: cubit!,
                        child: const SocialSearchScreen(),
                      );
                    },
                  ),
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
        path: AppRoutes.cynChat,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CynChatScreen(),
      ),
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
        path: AppRoutes.challengesMap,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final focus = state.uri.queryParameters['focus'];
          return ChallengesMapScreen(focusChallengeId: focus);
        },
        routes: [
          GoRoute(
            path: ':id/route',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final mode = state.extra is TravelMode ? state.extra! as TravelMode : TravelMode.motorbike;
              return RouteMapScreen(challengeId: id, initialMode: mode);
            },
          ),
          GoRoute(
            path: ':id',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return ChallengeDetailScreen(challengeId: id);
            },
          ),
        ],
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
      ),
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
      GoRoute(
        path: AppRoutes.nutritionDiary,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const NutritionDiaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.nutritionFoodSearch,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final meal = state.extra is MealTypeUi ? state.extra! as MealTypeUi : MealTypeUi.snack;
          return FoodSearchScreen(mealType: meal);
        },
      ),
      GoRoute(
        path: AppRoutes.nutritionCreateFood,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateFoodScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplaceHome,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MarketplaceHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplaceListing,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filter = state.extra is MarketplaceListingFilter
              ? state.extra! as MarketplaceListingFilter
              : MarketplaceListingFilter.all;
          return MarketplaceListingScreen(filter: filter);
        },
      ),
      GoRoute(
        path: AppRoutes.marketplaceSearch,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MarketplaceSearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.marketplaceKitchens,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final kitchens = state.extra is List<KitchenCardVm>
              ? state.extra! as List<KitchenCardVm>
              : const <KitchenCardVm>[];
          return NearbyKitchensScreen(kitchens: kitchens);
        },
      ),
      GoRoute(
        path: '/marketplace/partner/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            PartnerDetailScreen(partnerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/marketplace/food/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            FoodMenuItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/marketplace/affiliate/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            AffiliateProductDetailScreen(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.marketplaceWriteReview,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra as Map<String, String?>? ?? {};
          return WriteReviewScreen(
            targetType: extra['targetType'] ?? 'Partner',
            targetId: extra['targetId'] ?? '',
            orderId: extra['orderId'],
          );
        },
      ),
      GoRoute(
        path: AppRoutes.orderCart,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderCheckout,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final order = state.extra as OrderSummary;
          final toOrders = state.uri.queryParameters['toOrders'] == '1';
          return OrderSuccessScreen(order: order, navigateToOrders: toOrders);
        },
      ),
      GoRoute(
        path: AppRoutes.orderList,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialTab = tab == 'active' ? 0 : tab == 'history' ? 1 : 0;
          return OrderListScreen(initialTabIndex: initialTab);
        },
      ),
      GoRoute(
        path: '/orders/:id/tracking',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            OrderTrackingScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
    ],
  );
}
