import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/features/workouts/cubit/workouts_cubit.dart';
import 'package:sync_app/features/workouts/data/exercise_catalog_promos.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/exercise_catalog_theme.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_ai_recommended_section.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_exercise_card.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_hero_carousel.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_muscle_groups_section.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_search_filters.dart';

/// Premium exercise catalog — main content for the Workouts "Catalog" tab.
class CatalogTabView extends StatefulWidget {
  const CatalogTabView({super.key});

  @override
  State<CatalogTabView> createState() => _CatalogTabViewState();
}

class _CatalogTabViewState extends State<CatalogTabView> {
  final _searchController = TextEditingController();
  String _category = ExerciseCatalogCategories.all;
  String? _muscleKeyword;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<WorkoutsCubit>().state;
      if (state.exercises.isEmpty && state.catalogStatus != LoadStatus.loading) {
        _load();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _load);
  }

  void _load() {
    if (!mounted) return;
    final query = _searchController.text.trim();
    context.read<WorkoutsCubit>().loadCatalog(
          query: query.isEmpty ? null : query,
          category: _category,
        );
  }

  List<ExerciseCatalogItem> _filterByMuscle(List<ExerciseCatalogItem> items) {
    final kw = _muscleKeyword;
    if (kw == null || kw.isEmpty) return items;
    final needle = kw.toLowerCase();
    return items.where((e) {
      final haystack = [
        ...e.primaryMuscles,
        e.bodyRegion,
        e.bodyRegionGroupTitle,
        e.nameEn,
        e.nameVi,
      ].join(' ').toLowerCase();
      return haystack.contains(needle);
    }).toList();
  }

  void _openDetail(ExerciseCatalogItem exercise) {
    context.push(AppRoutes.exerciseDetail(exercise.id), extra: exercise);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ExerciseCatalogTheme.offWhite,
      child: BlocBuilder<WorkoutsCubit, WorkoutsState>(
        builder: (context, state) {
          final allExercises = state.exercises;
          final exercises = _filterByMuscle(allExercises);
          final loading = state.catalogStatus == LoadStatus.loading && allExercises.isEmpty;
          final error = state.catalogError;

          final aiRecommended = exercises.where((e) => e.isAiRecommended).toList();

          if (loading) {
            return const CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: ExerciseCatalogTheme.syncLime),
                  ),
                ),
              ],
            );
          }

          if (error != null && allExercises.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    TextButton(onPressed: _load, child: const Text('Thử lại')),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: ExerciseCatalogTheme.slateDark,
            backgroundColor: ExerciseCatalogTheme.syncLime,
            onRefresh: () async => _load(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              slivers: [
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: CatalogHeroCarousel(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: CatalogSearchFilters(
                      searchController: _searchController,
                      selectedCategory: _category,
                      onSearchSubmitted: _load,
                      onCategorySelected: (c) {
                        setState(() => _category = c);
                        _load();
                      },
                    ),
                  ),
                ),
                if (aiRecommended.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                      child: CatalogAiRecommendedSection(
                        exercises: aiRecommended,
                        onTap: _openDetail,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: CatalogMuscleGroupsSection(
                      selectedKeyword: _muscleKeyword,
                      onSelected: (kw) => setState(() => _muscleKeyword = kw),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                    child: exercises.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 48),
                              child: Text(
                                'Không tìm thấy bài tập.',
                                style: TextStyle(color: ExerciseCatalogTheme.slateMuted),
                              ),
                            ),
                          )
                        : CatalogAllExercisesGrid(
                            exercises: exercises,
                            onTapExercise: _openDetail,
                          ),
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
