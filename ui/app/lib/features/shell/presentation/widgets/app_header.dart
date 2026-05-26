import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/route_constants.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.displayName = 'Khai',
    this.avatarUrl,
    this.onNotificationTap,
  });

  final String displayName;
  final String? avatarUrl;
  final VoidCallback? onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final firstName = displayName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.go(RouteConstants.profile),
            borderRadius: BorderRadius.circular(28),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SyncColors.cyan.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: SyncColors.surfaceElevated,
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.person, color: SyncColors.cyan)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Hi, $firstName',
                  style: const TextStyle(
                    color: SyncColors.cyan,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Material(
            color: SyncColors.surfaceElevated,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onNotificationTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Thông báo — sắp có')),
                    );
                  },
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.notifications_none_rounded,
                  color: SyncColors.textPrimary,
                  size: 26,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
