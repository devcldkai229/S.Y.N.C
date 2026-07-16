import 'dart:async';

import 'package:flutter/foundation.dart';
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
import 'package:sync_app/shared/widgets/google_mark.dart';
// Web-only import: compiled only when targeting Web via conditional import.
// On non-Web platforms this file doesn't exist, but it's guarded by kIsWeb.
import 'package:google_sign_in_web/web_only.dart'
    if (dart.library.io) 'package:sync_app/features/auth/screens/_stub_web_only.dart'
    as google_sign_in_web_only;

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

  // Web-only: GIS requires renderButton(); we listen to authenticationEvents stream.
  StreamSubscription<GoogleSignInAuthenticationEvent>? _webGoogleSub;

  @override
  void initState() {
    super.initState();
    _isAuthEnabled = getIt.isRegistered<AuthRepository>();
    if (_isAuthEnabled) {
      _authRepository = getIt<AuthRepository>();
    }
    // On Web, subscribe to the GIS sign-in stream so renderButton() can trigger login.
    if (kIsWeb && _isAuthEnabled) {
      _initWebGoogleStream();
    }
  }

  void _initWebGoogleStream() {
    // Initialize GoogleSignIn (idempotent — safe to call multiple times).
    // Must complete before renderButton() works and before the stream fires.
    _authRepository.ensureGoogleSignInInitialized().then((_) {
      if (!mounted) return;
      // GoogleSignIn.instance.authenticationEvents is the correct v7 stream.
      // It emits GoogleSignInAuthenticationEventSignIn when renderButton() is clicked.
      _webGoogleSub = GoogleSignIn.instance.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) async {
          if (!mounted) return;
          if (event is GoogleSignInAuthenticationEventSignIn) {
            setState(() => _isGoogleLoading = true);
            try {
              await _authRepository.signInWithGoogleAccount(event.user);
              if (!mounted) return;
              await navigateAfterAuth(context);
            } catch (error) {
              if (mounted) _showError(_mapError(error, context.l10n));
            } finally {
              if (mounted) setState(() => _isGoogleLoading = false);
            }
          }
        },
        onError: (Object e) {
          if (mounted) _showError('Google Sign-In error: $e');
        },
      );
    }).catchError((Object e) {
      // Initialization failure — show error, button will not work.
      if (mounted) _showError('Google Sign-In không khởi động được: $e');
    });
  }

  @override
  void dispose() {
    _webGoogleSub?.cancel();
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
                            if (kIsWeb)
                              // GIS on Web requires the official button widget.
                              // Wrap it in a styled container to fit the design.
                              _GoogleWebButtonWrapper(
                                isLoading: _isGoogleLoading,
                              )
                            else
                              _SocialCircleButton(
                                isLoading: _isGoogleLoading,
                                onPressed: _onGooglePressed,
                                child: const GoogleMark(size: 22),
                              ),
                            const SizedBox(width: 20),
                            _SocialCircleButton(
                              onPressed: _onApplePressed,
                              child: const Icon(Icons.apple_rounded, size: 26),
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
    required this.child,
    required this.onPressed,
    this.isLoading = false,
  });

  final Widget child;
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
            : child,
      ),
    );
  }
}

/// Web-only widget that renders [GoogleSignIn.instance.renderButton()].
/// GIS (google_sign_in_web v1.x) does not support programmatic sign-in;
/// the official button is the only way to trigger the sign-in flow.
/// The [onCurrentUserChanged] stream in [_LoginScreenState._initWebGoogleStream]
/// handles the result asynchronously.
class _GoogleWebButtonWrapper extends StatelessWidget {
  const _GoogleWebButtonWrapper({this.isLoading = false});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Styled backdrop that matches the other social buttons.
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
          // The official GIS button via web_only.renderButton().
          // ClipOval clips it to match the circular button design.
          ClipOval(
            child: google_sign_in_web_only.renderButton(),
          ),
          // Loading overlay.
          if (isLoading)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.45),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
