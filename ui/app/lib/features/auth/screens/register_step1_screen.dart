import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/features/auth/utils/auth_error_mapper.dart';
import 'package:sync_app/shared/widgets/custom_text_field.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';
import 'package:sync_app/shared/widgets/progress_header.dart';

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
  bool _isCodeSent = false;
  bool _isEmailVerified = false;
  String _registeredEmail = '';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ProgressHeader(
              currentStep: _isEmailVerified ? 3 : (_isCodeSent ? 2 : 1),
              totalSteps: 3,
              onClose: () => context.go(AppRoutes.login),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: LanguageIconToggle(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEmailVerified
                          ? 'Hoàn tất đăng ký'
                          : (_isCodeSent
                              ? context.l10n.verifyEmailTitle
                              : context.l10n.registerTitle),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isEmailVerified
                          ? 'Email đã xác minh. Nhập mật khẩu và bấm Tiếp tục để hoàn tất đăng ký.'
                          : (_isCodeSent
                              ? 'Mã xác minh đã được gửi đến ${_registeredEmail.isEmpty ? _emailController.text.trim() : _registeredEmail}. Bạn có thể xác minh mã trước, chưa cần nhập mật khẩu.'
                              : context.l10n.registerSubtitle),
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    CustomTextField(
                      label: context.l10n.fullNameLabel,
                      hint: 'FitWarrior',
                      controller: _usernameController,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.emailLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'hello@vitality.com',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _onSendCodePressed,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                            ),
                            child: Text(
                              _isCodeSent ? 'Resend code' : 'Verify email',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Mã xác minh email',
                      hint: 'Nhập mã 6 số gửi về email',
                      controller: _verificationCodeController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nếu SMTP tắt, mã sẽ xuất hiện trong log IAM.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: context.l10n.passwordLabel,
                      hint: '••••••••',
                      controller: _passwordController,
                      obscureText: true,
                      showToggleVisibility: true,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: context.l10n.confirmPasswordLabel,
                      hint: '••••••••',
                      controller: _confirmPasswordController,
                      obscureText: true,
                      showToggleVisibility: true,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: context.l10n.actionContinue,
                    isLoading: _isLoading,
                    onPressed: _onContinuePressed,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        _showMessage('Vui lòng nhấn "Verify email" để gửi mã xác minh trước.');
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onSendCodePressed() async {
    if (_isLoading) return;
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.isEmpty || email.isEmpty) {
      _showMessage('Vui lòng nhập họ tên và email trước khi xác minh.');
      return;
    }

    setState(() => _isLoading = true);
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _extractToken(String input) {
    // Hỗ trợ cả khi người dùng dán full URL verify-email.
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
