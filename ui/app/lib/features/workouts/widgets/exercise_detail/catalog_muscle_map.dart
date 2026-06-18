import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/catalog_assets.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';

/// Body diagram + primary/secondary muscle chips (Hevy-style minimum viable muscle map).
class CatalogMuscleMap extends StatelessWidget {
  const CatalogMuscleMap({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
  });

  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ExerciseCatalogTheme.frostedCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cơ tác động',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  CatalogAssets.bodyFront,
                  width: 120,
                  height: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    height: 160,
                    color: ExerciseCatalogTheme.syncLime.withValues(alpha: 0.2),
                    child: const Icon(Icons.accessibility_new_rounded, size: 64, color: ExerciseCatalogTheme.slateMuted),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (primaryMuscles.isNotEmpty) ...[
                      const Text('Chính', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ExerciseCatalogTheme.slateMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: primaryMuscles.map((m) => _MuscleChip(label: m, primary: true)).toList(),
                      ),
                    ],
                    if (secondaryMuscles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Phụ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: ExerciseCatalogTheme.slateMuted)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: secondaryMuscles.map((m) => _MuscleChip(label: m, primary: false)).toList(),
                      ),
                    ],
                    if (primaryMuscles.isEmpty && secondaryMuscles.isEmpty)
                      const Text('Chưa có dữ liệu nhóm cơ.', style: TextStyle(color: ExerciseCatalogTheme.slateMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label, required this.primary});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: primary
            ? ExerciseCatalogTheme.syncLime.withValues(alpha: primary ? 0.55 : 0.2)
            : ExerciseCatalogTheme.borderSoft.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: primary ? ExerciseCatalogTheme.syncLime : ExerciseCatalogTheme.borderSoft,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: primary ? FontWeight.w900 : FontWeight.w600,
          color: ExerciseCatalogTheme.slateDark,
        ),
      ),
    );
  }
}
