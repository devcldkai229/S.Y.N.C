import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Cài Đặt',
        style: TextStyle(
          color: SyncColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
