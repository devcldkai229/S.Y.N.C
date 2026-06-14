import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_thumbnail.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_helpers.dart';
class CatalogAiRecommendedSection extends StatelessWidget {
  const CatalogAiRecommendedSection({
    super.key,
    required this.exercises,
    required this.onTap,
  });

  final List<ExerciseCatalogItem> exercises;
  final ValueChanged<ExerciseCatalogItem> onTap;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'AI Recommended',
          subtitle: 'Tối ưu cho mục tiêu hiện tại của bạn',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            itemCount: exercises.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _AiRecommendedCard(
              exercise: exercises[i],
              onTap: () => onTap(exercises[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _AiRecommendedCard extends StatelessWidget {
  const _AiRecommendedCard({required this.exercise, required this.onTap});

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = exercise; // use CatalogExerciseThumbnail

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: ExerciseCatalogTheme.cardWhite,
          boxShadow: [ExerciseCatalogTheme.softShadow],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CatalogExerciseThumbnail(exercise: thumb, fill: true, borderRadius: 0),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ExerciseCatalogTheme.syncLime,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${exercise.metValue.toStringAsFixed(1)} MET',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: ExerciseCatalogTheme.slateDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.nameVi.isNotEmpty ? exercise.nameVi : exercise.nameEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: ExerciseCatalogTheme.slateDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CatalogHelpers.displayMuscles(exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: ExerciseCatalogTheme.slateMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: ExerciseCatalogTheme.slateMuted,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 13, color: ExerciseCatalogTheme.slateLight),
          ),
        ],
      ],
    );
  }
}
