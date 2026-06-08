import 'package:flutter/material.dart';
import 'package:sync_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/features/auth/utils/auth_error_mapper.dart';
import 'package:sync_app/features/auth/utils/auth_navigation.dart';
import 'package:sync_app/shared/widgets/custom_text_field.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';
import 'package:sync_app/shared/widgets/glass_card.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';
import 'package:sync_app/shared/widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthRepository _authRepository;
  late final bool _isAuthEnabled;
  bool _rememberMe = true;
  bool _isLoginLoading = false;
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    _isAuthEnabled = getIt.isRegistered<AuthRepository>();
    if (_isAuthEnabled) {
      _authRepository = getIt<AuthRepository>();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          _LoginBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: const LanguageIconToggle(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.appTitle,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.loginTagline,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 40),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.loginWelcome,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.loginSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        CustomTextField(
                          label: context.l10n.emailLabel,
                          hint: 'hello@vitality.com',
                          controller: _emailController,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          label: context.l10n.passwordLabel,
                          hint: '••••••••',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: true,
                          showToggleVisibility: true,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.primaryGreen,
                                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            Text(
                              context.l10n.rememberMe,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () =>
                                  context.push(AppRoutes.forgotPassword),
                              child: Text(
                                context.l10n.forgotPassword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          label: context.l10n.signIn,
                          trailingIcon: Icons.arrow_forward_rounded,
                          isLoading: _isLoginLoading,
                          onPressed: _onLoginPressed,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.borderLight)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                context.l10n.orContinueWith.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.borderLight)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SocialLoginButton(
                          type: SocialLoginType.google,
                          isLoading: _isGoogleLoading,
                          onPressed: _onGooglePressed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: const Text(
                          'Register Now',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.brightGreen,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (!_isAuthEnabled) {
      if (!mounted) return;
      context.go(AppRoutes.home);
      return;
    }
    if (_isLoginLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showError('Please enter both email and password.');
      return;
    }

    setState(() => _isLoginLoading = true);
    try {
      await _authRepository.login(email: email, password: password);
      if (!mounted) return;
      await navigateAfterAuth(context);
    } catch (error) {
      _showError(_mapError(error, context.l10n));
    } finally {
      if (mounted) {
        setState(() => _isLoginLoading = false);
      }
    }
  }

  Future<void> _onGooglePressed() async {
    if (!_isAuthEnabled) {
      _showError('Auth service is not initialized.');
      return;
    }
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      await _authRepository.signInWithGoogle();
      if (!mounted) return;
      await navigateAfterAuth(context);
    } catch (error) {
      _showError(_mapError(error, context.l10n));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  String _mapError(Object error, AppLocalizations l10n) {
    if (error is GoogleSignInException) {
      final desc = error.description ?? '';
      if (desc.contains('[16]') || desc.contains('reauth failed')) {
        return 'Google Sign-In thất bại (lỗi cấu hình OAuth). '
            'Vào Google Cloud Console → Credentials → Android client, '
            'thêm SHA-1 debug: ED:16:02:D9:E4:B6:48:68:9F:BD:8A:48:18:1E:AD:A1:C0:ED:0F:01 '
            'và package com.sync.sync_app. '
            'Thêm Gmail của bạn vào OAuth consent screen → Test users.';
      }
      return 'Google Sign-In (${error.code.name}): ${desc.isEmpty ? 'Unknown error' : desc}';
    }
    return mapAuthError(error, l10n);
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
  }
}

class _LoginBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2918),
            Color(0xFF1A3D24),
            Color(0xFF0D1F14),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.loginOverlay.withValues(alpha: 0.5),
              AppColors.loginOverlay,
            ],
          ),
        ),
      ),
    );
  }
}
