import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/shared/widgets/google_mark.dart';

enum SocialLoginType { google }

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.cardBackground,
          side: const BorderSide(color: AppColors.borderLight),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GoogleMark(size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Google',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
