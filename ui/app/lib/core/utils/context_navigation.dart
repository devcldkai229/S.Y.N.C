import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';

extension ContextNavigationX on BuildContext {
  /// Pops when possible; otherwise returns to the main home shell.
  void popOrGoHome() {
    if (canPop()) {
      pop();
      return;
    }
    go(AppRoutes.home);
  }
}
