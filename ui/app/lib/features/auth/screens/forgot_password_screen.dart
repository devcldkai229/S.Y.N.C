import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/auth_repository.dart';
import 'package:sync_app/features/auth/utils/auth_error_mapper.dart';
import 'package:sync_app/shared/widgets/custom_text_field.dart';
import 'package:sync_app/shared/widgets/language_switcher.dart';
import 'package:sync_app/shared/widgets/primary_button.dart';

/// Two-step forgot-password flow: request a 6-digit code, then set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthRepository _authRepository;
  late final bool _isAuthEnabled;
  bool _isLoading = false;
  bool _isCodeSent = false;
  String _sentEmail = '';

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
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Quên mật khẩu'),
        actions: const [LanguageIconToggle(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCodeSent ? 'Đặt lại mật khẩu' : 'Quên mật khẩu?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _isCodeSent
                    ? 'Nhập mã 6 số đã gửi đến $_sentEmail cùng mật khẩu mới của bạn.'
                    : 'Nhập email của bạn, chúng tôi sẽ gửi mã 6 số để đặt lại mật khẩu.',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: context.l10n.emailLabel,
                hint: 'hello@vitality.com',
                controller: _emailController,
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mã đặt lại mật khẩu',
                  hint: 'Nhập mã 6 số gửi về email',
                  controller: _codeController,
                  prefixIcon: Icons.shield_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nếu SMTP tắt, mã sẽ xuất hiện trong log IAM. Mã có hiệu lực 15 phút.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Mật khẩu mới',
                  hint: '••••••••',
                  controller: _passwordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  showToggleVisibility: true,
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  label: context.l10n.confirmPasswordLabel,
                  hint: '••••••••',
                  controller: _confirmPasswordController,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  showToggleVisibility: true,
                ),
              ],
              const SizedBox(height: 32),
              PrimaryButton(
                label: _isCodeSent ? 'Đặt lại mật khẩu' : 'Gửi mã',
                isLoading: _isLoading,
                onPressed: _isCodeSent ? _onResetPressed : _onSendCodePressed,
              ),
              if (_isCodeSent) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _onSendCodePressed,
                    child: const Text('Gửi lại mã'),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(context.l10n.hasAccountLogin),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSendCodePressed() async {
    if (!_isAuthEnabled) {
      _showMessage('Auth service is not initialized.');
      return;
    }
    if (_isLoading) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Vui lòng nhập email.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await _authRepository.forgotPassword(email: email);
      if (!mounted) return;
      _showMessage(message);
      setState(() {
        _isCodeSent = true;
        _sentEmail = email;
      });
    } catch (error) {
      _showMessage(mapAuthError(error, context.l10n));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onResetPressed() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || code.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ email, mã và mật khẩu mới.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Mật khẩu phải có ít nhất 8 ký tự.');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Xác nhận mật khẩu không khớp.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await _authRepository.resetPassword(
        email: email,
        code: code,
        newPassword: password,
      );
      if (!mounted) return;
      _showMessage(message);
      context.go(AppRoutes.login);
    } catch (error) {
      _showMessage(mapAuthError(error, context.l10n));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
