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

/// Verifies email using the token from the registration email (or IAM console log when SMTP is off).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, this.initialToken});

  final String? initialToken;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final TextEditingController _tokenController;
  late final AuthRepository _authRepository;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
    _authRepository = getIt<AuthRepository>();
    if ((widget.initialToken ?? '').trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _onVerifyPressed());
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(context.l10n.verifyEmailTitle),
        actions: const [LanguageIconToggle(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.verifyEmailTitle,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.verifyEmailHint,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                label: context.l10n.verifyEmailTitle,
                hint: context.l10n.verifyEmailHint,
                controller: _tokenController,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: context.l10n.verifyEmailButton,
                isLoading: _isLoading,
                onPressed: _onVerifyPressed,
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(context.l10n.hasAccountLogin),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onVerifyPressed() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await _authRepository.verifyEmail(_tokenController.text);
      if (!mounted) return;
      _showMessage('Email ${result.email} đã được xác minh. Bạn có thể đăng nhập.');
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
