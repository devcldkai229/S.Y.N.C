import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hồ Sơ',
        style: TextStyle(
          color: SyncColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
