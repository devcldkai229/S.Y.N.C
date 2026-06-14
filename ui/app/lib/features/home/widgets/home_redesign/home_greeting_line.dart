import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/data/home_display_helpers.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeGreetingLine extends StatelessWidget {
  const HomeGreetingLine({super.key, required this.data});

  final HomeDashboardData data;

  @override
  Widget build(BuildContext context) {
    final name = data.greetingName.isNotEmpty ? data.greetingName : 'bạn';
    return Text(
      '${HomeDisplayHelpers.timeGreeting()}, $name 👋',
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: HomeBentoColors.textPrimary,
        height: 1.2,
      ),
    );
  }
}
