import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/sync_colors.dart';
import 'package:sync_app/features/home/presentation/widgets/body_wireframe.dart';
import 'package:sync_app/features/home/presentation/widgets/home_stat_card.dart';
import 'package:sync_app/features/home/presentation/widgets/perspective_grid_painter.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    this.caloriesKcal = 842,
    this.streakDays = 14,
  });

  final int caloriesKcal;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            height: constraints.maxHeight,
            decoration: BoxDecoration(
              color: SyncColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: SyncColors.cyan.withValues(alpha: 0.25)),
              boxShadow: SyncColors.cyanGlow(blur: 32, spread: -8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: PerspectiveGridPainter()),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: BodyWireframe(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomeStatCard(
                    label: 'CALORIES',
                    value: '$caloriesKcal kcal',
                    icon: Icons.local_fire_department_outlined,
                    valueColor: SyncColors.cyan,
                    alignment: Alignment.topLeft,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: HomeStatCard(
                    label: 'STREAK',
                    value: '$streakDays days',
                    icon: Icons.bolt,
                    valueColor: SyncColors.lime,
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
