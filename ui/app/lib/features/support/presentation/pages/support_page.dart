import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Hỗ Trợ',
        style: TextStyle(
          color: SyncColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
