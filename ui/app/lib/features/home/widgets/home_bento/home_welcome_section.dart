import 'package:flutter/material.dart';
import 'package:sync_app/data/models/home_dashboard_models.dart';
import 'package:sync_app/features/home/widgets/home_bento/home_bento_styles.dart';

class HomeWelcomeSection extends StatelessWidget {
  const HomeWelcomeSection({super.key, required this.data});

  final HomeDashboardData data;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  @override
  Widget build(BuildContext context) {
    final name = data.greetingName.isNotEmpty ? data.greetingName : 'Khải';
    final phase = data.phaseLabel?.isNotEmpty == true ? data.phaseLabel! : 'Foundation';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greeting()}, $name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Sẵn sàng để chinh phục $phase hôm nay.',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: HomeBentoColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
