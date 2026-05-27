import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/app/router/app_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';

/// Đóng dialog (nếu có) rồi vào shell Home — không ép onboarding để tránh kẹt màn hình.
Future<void> navigateAfterAuth(BuildContext context) async {
  final rootNav = rootNavigatorKey.currentState;
  if (rootNav != null) {
    rootNav.popUntil((route) => route is! PopupRoute);
  }
  if (!context.mounted) return;
  context.go(AppRoutes.home);
}
