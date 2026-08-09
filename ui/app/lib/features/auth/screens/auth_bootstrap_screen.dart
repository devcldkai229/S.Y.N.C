import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/network/token_refresh_coordinator.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/auth/utils/auth_navigation.dart';

/// Cold-start gate: restore long-lived session via refresh token, else login.
class AuthBootstrapScreen extends StatefulWidget {
  const AuthBootstrapScreen({super.key});

  @override
  State<AuthBootstrapScreen> createState() => _AuthBootstrapScreenState();
}

class _AuthBootstrapScreenState extends State<AuthBootstrapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _goLogin() async {
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  Future<void> _goAuthenticated() async {
    if (!mounted) return;
    await navigateAfterAuth(context);
  }

  Future<void> _bootstrap() async {
    final auth = getIt<AuthService>();
    final coordinator = getIt<TokenRefreshCoordinator>();

    try {
      final hasSession = await coordinator.hasPersistedSession();
      if (!hasSession) {
        await _goLogin();
        return;
      }

      // Soft refresh — network blip must NOT wipe tokens / kick to login.
      await coordinator.getValidAccessToken(notifyOnFailure: false);

      if (!await auth.isLoggedIn()) {
        await _goLogin();
        return;
      }

      await _goAuthenticated();
    } catch (_) {
      if (await auth.isLoggedIn()) {
        await _goAuthenticated();
      } else {
        await _goLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primaryGreen,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Đang khôi phục phiên…',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
