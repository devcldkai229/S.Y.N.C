import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/locale/locale_cubit.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/shared/widgets/notification_bell_button.dart';

/// Premium, consistent top app bar for SYNC shell screens.
class SyncAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SyncAppBar({
    super.key,
    this.isSocialScreen = false,
    this.embedded = false,
    this.backgroundColor = AppColors.cardBackground,
  });

  /// When `true`, shows the Messages action (Social tab).
  final bool isSocialScreen;

  /// Use inside scroll headers (e.g. Social feed) instead of [Scaffold.appBar].
  final bool embedded;

  final Color backgroundColor;

  static const _logoAsset = 'assets/images/sync_logo.png';
  static const _iconColor = Color(0xFF1E293B);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  void _showStub(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolbar = _SyncAppBarToolbar(
      isSocialScreen: isSocialScreen,
      backgroundColor: backgroundColor,
      onAiTap: () => context.push(AppRoutes.cynChat),
      onMessagesTap: () => _showStub(context, 'Tin nhắn đang phát triển'),
    );

    return toolbar;
  }
}

class _SyncAppBarToolbar extends StatelessWidget {
  const _SyncAppBarToolbar({
    required this.isSocialScreen,
    required this.backgroundColor,
    required this.onAiTap,
    required this.onMessagesTap,
  });

  final bool isSocialScreen;
  final Color backgroundColor;
  final VoidCallback onAiTap;
  final VoidCallback onMessagesTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SizedBox(
        height: kToolbarHeight,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Image.asset(
              SyncAppBar._logoAsset,
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Text(
                'SYNC',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            const Spacer(),
            const _LanguageViEnChip(),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onAiTap,
              icon: const Icon(Icons.smart_toy_outlined, color: SyncAppBar._iconColor),
              tooltip: 'AI Agent',
            ),
            const NotificationBellButton(
              iconColor: SyncAppBar._iconColor,
              iconSize: 24,
            ),
            if (isSocialScreen)
              IconButton(
                onPressed: onMessagesTap,
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: SyncAppBar._iconColor),
                tooltip: 'Tin nhắn',
              ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

class _LanguageViEnChip extends StatelessWidget {
  const _LanguageViEnChip();

  @override
  Widget build(BuildContext context) {
    final code = context.watch<LocaleCubit>().currentCode;
    final isVi = code == 'vi';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.read<LocaleCubit>().changeLanguage(isVi ? 'en' : 'vi'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.backgroundAlt,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'VI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isVi ? FontWeight.w800 : FontWeight.w500,
                  color: isVi ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '/',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
              Text(
                'EN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: !isVi ? FontWeight.w800 : FontWeight.w500,
                  color: !isVi ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
