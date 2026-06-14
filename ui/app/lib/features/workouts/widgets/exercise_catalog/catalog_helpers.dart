import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';

abstract final class CatalogHelpers {
  static String displayMuscles(ExerciseCatalogItem exercise) =>
      exercise.primaryMuscles.take(2).join(' · ');

  static Color difficultyColor(String difficulty) {
    final d = difficulty.toLowerCase();
    if (d.contains('advanced')) return ExerciseCatalogTheme.dangerRed;
    if (d.contains('intermediate')) return ExerciseCatalogTheme.intermediateAmber;
    return ExerciseCatalogTheme.beginnerGreen;
  }

  static String difficultyLabel(String difficulty) {
    if (difficulty.isEmpty) return 'All levels';
    return difficulty
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');
  }

  static String? thumbnailFor(ExerciseCatalogItem exercise) {
    if (exercise.thumbnailUrl != null && exercise.thumbnailUrl!.isNotEmpty) {
      return exercise.thumbnailUrl;
    }
    return null;
  }

  static Widget thumbnailPlaceholder({double size = 56, IconData icon = Icons.fitness_center}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ExerciseCatalogTheme.syncLime.withValues(alpha: 0.35),
            ExerciseCatalogTheme.slateDark.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Icon(icon, color: ExerciseCatalogTheme.slateDark.withValues(alpha: 0.45), size: size * 0.45),
    );
  }
}
