import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_thumbnail.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_helpers.dart';

class CatalogExerciseCard extends StatelessWidget {
  const CatalogExerciseCard({
    super.key,
    required this.exercise,
    required this.onTap,
    this.compact = false,
  });

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _GridCard(exercise: exercise, onTap: onTap);
    return _ListCard(exercise: exercise, onTap: onTap);
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.exercise, required this.onTap});

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diffColor = CatalogHelpers.difficultyColor(exercise.difficulty);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ExerciseCatalogTheme.cardWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: ExerciseCatalogTheme.borderSoft),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CatalogExerciseThumbnail(exercise: exercise, width: 80, height: 80),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.nameVi.isNotEmpty ? exercise.nameVi : exercise.nameEn,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark),
                      ),
                      const SizedBox(height: 4),
                      Text(CatalogHelpers.displayMuscles(exercise), style: const TextStyle(fontSize: 12, color: ExerciseCatalogTheme.slateMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Badge(label: CatalogHelpers.difficultyLabel(exercise.difficulty), color: diffColor),
                          _Badge(label: '${exercise.metValue.toStringAsFixed(1)} MET', color: ExerciseCatalogTheme.slateDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: ExerciseCatalogTheme.slateMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.exercise, required this.onTap});

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ExerciseCatalogTheme.cardWhite,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CatalogExerciseThumbnail(exercise: exercise, fill: true, borderRadius: 0),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: ExerciseCatalogTheme.syncLime,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${exercise.metValue.toStringAsFixed(1)} MET',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.nameVi.isNotEmpty ? exercise.nameVi : exercise.nameEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark, height: 1.15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CatalogHelpers.displayMuscles(exercise),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: ExerciseCatalogTheme.slateMuted),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class CatalogExerciseGroup extends StatelessWidget {
  const CatalogExerciseGroup({
    super.key,
    required this.title,
    required this.exercises,
    required this.onTapExercise,
  });

  final String title;
  final List<ExerciseCatalogItem> exercises;
  final ValueChanged<ExerciseCatalogItem> onTapExercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ExerciseCatalogTheme.slateDark)),
        ),
        ...exercises.map((e) => CatalogExerciseCard(exercise: e, onTap: () => onTapExercise(e))),
      ],
    );
  }
}

class CatalogAllExercisesGrid extends StatefulWidget {
  const CatalogAllExercisesGrid({
    super.key,
    required this.exercises,
    required this.onTapExercise,
    this.initialVisibleCount,
    this.pageSize = 8,
  });

  final List<ExerciseCatalogItem> exercises;
  final ValueChanged<ExerciseCatalogItem> onTapExercise;
  final int? initialVisibleCount;
  final int pageSize;

  @override
  State<CatalogAllExercisesGrid> createState() => _CatalogAllExercisesGridState();
}

class _CatalogAllExercisesGridState extends State<CatalogAllExercisesGrid> {
  late int _visibleCount;

  @override
  void initState() {
    super.initState();
    _visibleCount = (widget.initialVisibleCount ?? 8).clamp(0, widget.exercises.length);
  }

  @override
  void didUpdateWidget(covariant CatalogAllExercisesGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercises.length != widget.exercises.length) {
      _visibleCount = (widget.initialVisibleCount ?? 8).clamp(0, widget.exercises.length);
    }
  }

  void _showMore() {
    setState(() {
      _visibleCount = (_visibleCount + widget.pageSize).clamp(0, widget.exercises.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.exercises.take(_visibleCount).toList();
    final hasMore = _visibleCount < widget.exercises.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'TẤT CẢ BÀI TẬP',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: ExerciseCatalogTheme.slateMuted),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: visible.length,
          itemBuilder: (context, i) => CatalogExerciseCard(
            exercise: visible[i],
            compact: true,
            onTap: () => widget.onTapExercise(visible[i]),
          ),
        ),
        if (hasMore) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: _showMore,
              icon: const Icon(Icons.expand_more_rounded, size: 18),
              label: Text('Xem thêm (${widget.exercises.length - _visibleCount})'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ExerciseCatalogTheme.slateDark,
                side: const BorderSide(color: ExerciseCatalogTheme.borderSoft),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CatalogSkeleton extends StatelessWidget {
  const CatalogSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        4,
        (_) => Container(
          height: 88,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: ExerciseCatalogTheme.borderSoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
