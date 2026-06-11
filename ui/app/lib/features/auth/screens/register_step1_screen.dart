import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/features/auth/utils/auth_error_mapper.dart';
import 'package:sync_app/features/auth/widgets/auth_glass_ui.dart';
import 'package:sync_app/features/auth/widgets/login_video_background.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';

class RegisterStep1Screen extends StatefulWidget {
  const RegisterStep1Screen({super.key});

  @override
  State<RegisterStep1Screen> createState() => _RegisterStep1ScreenState();
}

class _RegisterStep1ScreenState extends State<RegisterStep1Screen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  late final AuthRepository _authRepository;
  late final bool _isAuthEnabled;

  bool _isLoading = false;
  bool _isSendingCode = false;
  bool _isCodeSent = false;
  bool _isEmailVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _registeredEmail = '';

  int get _currentStep => _isEmailVerified ? 3 : (_isCodeSent ? 2 : 1);

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isVi = Localizations.localeOf(context).languageCode == 'vi';

    final title = _isEmailVerified
        ? 'Hoàn tất đăng ký'
        : (_isCodeSent ? l10n.verifyEmailTitle : l10n.registerTitle);

    final subtitle = _isEmailVerified
        ? 'Email đã xác minh. Nhập mật khẩu và bấm Tiếp tục để hoàn tất đăng ký.'
        : (_isCodeSent
            ? 'Mã xác minh đã được gửi đến ${_registeredEmail.isEmpty ? _emailController.text.trim() : _registeredEmail}.'
            : (isVi
                ? 'Tham gia SYNC để bắt đầu hành trình bứt phá của bạn.'
                : l10n.registerSubtitle));

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const LoginVideoBackground(),
          const AuthBottomScrim(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        tooltip: 'Quay lại',
                      ),
                      const Spacer(),
                      const LanguageIconToggle(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AuthStepIndicator(currentStep: _currentStep),
                  const SizedBox(height: 28),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthFrostedTextField(
                          controller: _usernameController,
                          hint: l10n.fullNameLabel,
                          prefixIcon: Icons.person_outline_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 20),
                        AuthFrostedTextField(
                          controller: _emailController,
                          hint: l10n.emailLabel,
                          prefixIcon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          readOnly: _isEmailVerified,
                          suffix: AuthVerifyChip(
                            label: _isCodeSent ? 'Gửi lại' : 'Xác minh',
                            isLoading: _isSendingCode,
                            enabled: !_isEmailVerified,
                            onPressed: _onSendCodePressed,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AuthFrostedTextField(
                          controller: _verificationCodeController,
                          hint: 'Mã OTP (6 số)',
                          prefixIcon: Icons.verified_outlined,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.verifyEmailHint,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AuthFrostedTextField(
                          controller: _passwordController,
                          hint: l10n.passwordLabel,
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
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
                        const SizedBox(height: 20),
                        AuthFrostedTextField(
                          controller: _confirmPasswordController,
                          hint: l10n.confirmPasswordLabel,
                          prefixIcon: Icons.lock_reset_rounded,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _onContinuePressed(),
                          suffix: IconButton(
                            onPressed: () => setState(
                              () => _obscureConfirmPassword = !_obscureConfirmPassword,
                            ),
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  AuthCtaButton(
                    label: l10n.actionContinue,
                    isLoading: _isLoading,
                    onPressed: _onContinuePressed,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.login),
                        child: const Text(
                          'Đăng nhập',
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

  Future<void> _onContinuePressed() async {
    if (!_isAuthEnabled) {
      if (!mounted) return;
      context.go(AppRoutes.home);
      return;
    }
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty || email.isEmpty) {
      _showMessage('Vui lòng nhập họ tên và email.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEmailVerified) {
        if (password.isEmpty || confirmPassword.isEmpty) {
          _showMessage('Vui lòng nhập mật khẩu để hoàn tất đăng ký.');
          return;
        }
        if (password.length < 8) {
          _showMessage('Password must be at least 8 characters.');
          return;
        }
        if (password != confirmPassword) {
          _showMessage('Confirm password does not match.');
          return;
        }

        await _authRepository.finishRegistration(
          email: email,
          password: password,
        );
        if (!mounted) return;
        _showMessage('Đăng ký hoàn tất. Mời bạn đăng nhập.');
        context.go(AppRoutes.login);
        return;
      }

      if (!_isCodeSent) {
        _showMessage('Vui lòng nhấn "Xác minh" để gửi mã xác minh trước.');
        return;
      }

      final code = _extractToken(_verificationCodeController.text.trim());
      if (code.isEmpty) {
        _showMessage('Vui lòng nhập mã xác minh email.');
        return;
      }

      final hasPassword = password.isNotEmpty || confirmPassword.isNotEmpty;
      if (hasPassword) {
        if (password.isEmpty || confirmPassword.isEmpty) {
          _showMessage('Vui lòng nhập và xác nhận mật khẩu.');
          return;
        }
        if (password.length < 8) {
          _showMessage('Password must be at least 8 characters.');
          return;
        }
        if (password != confirmPassword) {
          _showMessage('Confirm password does not match.');
          return;
        }
      }

      final result = await _authRepository.completeRegistration(
        email: email,
        code: code,
        password: hasPassword ? password : null,
      );
      if (!mounted) return;

      if (hasPassword) {
        _showMessage(
          'Email ${result.email} đã xác minh và đăng ký hoàn tất. Mời bạn đăng nhập.',
        );
        context.go(AppRoutes.login);
      } else {
        _showMessage('Email ${result.email} đã xác minh. Nhập mật khẩu để hoàn tất.');
        setState(() => _isEmailVerified = true);
      }
    } catch (error) {
      _showMessage(mapAuthError(error, context.l10n));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onSendCodePressed() async {
    if (_isSendingCode || _isEmailVerified) return;

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.isEmpty || email.isEmpty) {
      _showMessage('Vui lòng nhập họ tên và email trước khi xác minh.');
      return;
    }

    setState(() => _isSendingCode = true);
    try {
      final result = _isCodeSent
          ? await _authRepository.resendVerificationCode(email: email)
          : await _authRepository.initRegistration(
              fullName: username,
              email: email,
            );
      if (!mounted) return;
      _showMessage(
        _isCodeSent
            ? 'Đã gửi lại mã xác minh mới về ${result.email}.'
            : 'Đã gửi mã xác minh về ${result.email}.',
      );
      setState(() {
        _isCodeSent = true;
        _isEmailVerified = false;
        _registeredEmail = result.email;
      });
    } catch (error) {
      _showMessage(mapAuthError(error, context.l10n));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  String _extractToken(String input) {
    final uri = Uri.tryParse(input);
    if (uri != null) {
      final q = uri.queryParameters['token'];
      if (q != null && q.isNotEmpty) return q;
    }
    return input;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
