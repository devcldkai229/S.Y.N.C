import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/catalog_assets.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';

class CatalogMuscleGroupsSection extends StatelessWidget {
  const CatalogMuscleGroupsSection({
    super.key,
    required this.selectedKeyword,
    required this.onSelected,
  });

  final String? selectedKeyword;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'Duyệt theo nhóm cơ'),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CatalogMuscleGroups.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = CatalogMuscleGroups.items[i];
              final selected = selectedKeyword == item.keyword;
              return _MuscleGroupChip(
                label: item.label,
                icon: item.icon,
                selected: selected,
                onTap: () => onSelected(selected ? null : item.keyword),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MuscleGroupChip extends StatelessWidget {
  const _MuscleGroupChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? ExerciseCatalogTheme.syncLime : ExerciseCatalogTheme.borderSoft,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected ? [ExerciseCatalogTheme.softShadow] : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: selected
                        ? [
                            ExerciseCatalogTheme.syncLime,
                            ExerciseCatalogTheme.syncLime.withValues(alpha: 0.55),
                          ]
                        : [
                            ExerciseCatalogTheme.offWhite,
                            ExerciseCatalogTheme.cardWhite,
                          ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 32,
                    color: selected ? ExerciseCatalogTheme.slateDark : ExerciseCatalogTheme.slateMuted,
                  ),
                ),
              ),
            ),
            Container(
              color: selected ? ExerciseCatalogTheme.syncLime : ExerciseCatalogTheme.cardWhite,
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ExerciseCatalogTheme.slateDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
        color: ExerciseCatalogTheme.slateMuted,
      ),
    );
  }
}
