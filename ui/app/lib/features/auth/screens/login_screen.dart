import 'package:flutter/material.dart';
import 'package:sync_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/features/auth/utils/auth_error_mapper.dart';
import 'package:sync_app/features/auth/utils/auth_navigation.dart';
import 'package:sync_app/features/auth/widgets/auth_glass_ui.dart';
import 'package:sync_app/features/auth/widgets/login_video_background.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';

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
  bool _obscurePassword = true;

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
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginVideoBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: LanguageIconToggle(),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SYNC',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 10,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 36),
                  AuthGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.loginWelcome,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        AuthFrostedTextField(
                          controller: _emailController,
                          hint: l10n.emailLabel,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        AuthFrostedTextField(
                          controller: _passwordController,
                          hint: l10n.passwordLabel,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onLoginPressed(),
                          suffix: IconButton(
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: Checkbox(
                                value: _rememberMe,
                                activeColor: authCtaGreen,
                                checkColor: Colors.black,
                                side: const BorderSide(color: Colors.white38),
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.rememberMe,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                foregroundColor: authCtaGreen,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                l10n.forgotPassword,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        AuthCtaButton(
                          label: l10n.signIn,
                          isLoading: _isLoginLoading,
                          onPressed: _onLoginPressed,
                        ),
                        const SizedBox(height: 28),
                        const _SubtleDivider(),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SocialCircleButton(
                              icon: Icons.g_mobiledata_rounded,
                              isLoading: _isGoogleLoading,
                              onPressed: _onGooglePressed,
                            ),
                            const SizedBox(width: 20),
                            _SocialCircleButton(
                              icon: Icons.apple_rounded,
                              onPressed: _onApplePressed,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push(AppRoutes.register),
                        child: const Text(
                          'Register',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: authCtaGreen,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: authCtaGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
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
      if (mounted) setState(() => _isLoginLoading = false);
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
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _onApplePressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In coming soon.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
  }
}

class _SubtleDivider extends StatelessWidget {
  const _SubtleDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.12))),
      ],
    );
  }
}

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          shape: const CircleBorder(),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.06),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(icon, size: icon == Icons.apple_rounded ? 26 : 30),
      ),
    );
  }
}
