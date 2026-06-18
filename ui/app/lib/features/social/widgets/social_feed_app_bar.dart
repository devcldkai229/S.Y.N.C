import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/shared/widgets/notification_bell_button.dart';

class SocialFeedAppBar extends StatelessWidget {
  const SocialFeedAppBar({super.key});

  void _showStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng đang phát triển'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardBackground,
      padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'SYNC Social',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: AppColors.primaryGreen,
              ),
            ),
          ),
          const NotificationBellButton(
            iconSize: 24,
            iconColor: AppColors.textPrimary,
          ),
          IconButton(
            onPressed: () => _showStub(context),
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            tooltip: 'Tin nhắn',
          ),
        ],
      ),
    );
  }
}
