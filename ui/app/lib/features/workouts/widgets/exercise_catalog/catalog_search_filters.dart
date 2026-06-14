import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/data/exercise_catalog_promos.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';

class CatalogSearchFilters extends StatelessWidget {
  const CatalogSearchFilters({
    super.key,
    required this.searchController,
    required this.selectedCategory,
    required this.onSearchSubmitted,
    required this.onCategorySelected,
  });

  final TextEditingController searchController;
  final String selectedCategory;
  final VoidCallback onSearchSubmitted;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ExerciseCatalogTheme.cardWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [ExerciseCatalogTheme.softShadow],
            border: Border.all(color: ExerciseCatalogTheme.borderSoft.withValues(alpha: 0.6)),
          ),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: searchController,
            builder: (context, value, _) {
              return TextField(
                controller: searchController,
                onSubmitted: (_) => onSearchSubmitted(),
                style: const TextStyle(color: ExerciseCatalogTheme.slateDark, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Tìm bài tập…',
                  hintStyle: TextStyle(color: ExerciseCatalogTheme.slateLight.withValues(alpha: 0.9)),
                  prefixIcon: Icon(Icons.search_rounded, color: ExerciseCatalogTheme.slateMuted.withValues(alpha: 0.8)),
                  suffixIcon: value.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: ExerciseCatalogTheme.slateMuted,
                          onPressed: () {
                            searchController.clear();
                            onSearchSubmitted();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: ExerciseCatalogCategories.options.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final category = ExerciseCatalogCategories.options[i];
              final selected = category == selectedCategory;
              final label = category == ExerciseCatalogCategories.all ? 'Tất cả' : category;
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (_) => onCategorySelected(category),
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? ExerciseCatalogTheme.slateDark : ExerciseCatalogTheme.slateMuted,
                ),
                backgroundColor: ExerciseCatalogTheme.cardWhite,
                selectedColor: ExerciseCatalogTheme.syncLime,
                side: BorderSide(
                  color: selected ? ExerciseCatalogTheme.syncLime : ExerciseCatalogTheme.borderSoft,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            },
          ),
        ),
      ],
    );
  }
}
