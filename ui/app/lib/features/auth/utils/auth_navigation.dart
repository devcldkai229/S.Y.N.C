import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/app/router/app_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/features/marketplace/cubit/marketplace_cart_cubit.dart';
import 'package:sync_app/features/order/state/active_order_count_notifier.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

/// Đóng dialog (nếu có) rồi điều hướng onboarding hoặc Home.
Future<void> navigateAfterAuth(BuildContext context) async {
  final rootNav = rootNavigatorKey.currentState;
  if (rootNav != null) {
    rootNav.popUntil((route) => route is! PopupRoute);
  }
  if (!context.mounted) return;

  if (getIt.isRegistered<ProfileApiService>()) {
    try {
      final settings = await getIt<ProfileApiService>().getProfileSettings();
      await getIt<LocaleCubit>().changeLanguage(settings.basic.preferredLanguage);
    } catch (_) {}
  }

  if (!context.mounted) return;

  await Future.wait([
    getIt<ActiveOrderCountNotifier>().refresh(),
    getIt<MarketplaceCartCubit>().hydrate(),
  ]);

  if (!context.mounted) return;

  final needsOnboarding = await getIt<AuthRepository>().needsOnboarding();
  if (!context.mounted) return;
  context.go(needsOnboarding ? AppRoutes.onboarding : AppRoutes.home);
}
