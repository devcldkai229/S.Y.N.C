import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/features/workouts/cubit/workouts_cubit.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_banner_carousel.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_section_header.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_template_card.dart';

/// Merged "Workouts" tab: user workouts + banner + community explore.
class WorkoutsMergedTab extends StatefulWidget {
  const WorkoutsMergedTab({super.key});

  @override
  State<WorkoutsMergedTab> createState() => _WorkoutsMergedTabState();
}

class _WorkoutsMergedTabState extends State<WorkoutsMergedTab> {
  final _searchController = TextEditingController();
  String _sortBy = 'newest';
  Timer? _debounce;
  static const _pageSize = 20;
  int _visibleTemplates = _pageSize;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (!mounted) return;
    final cubit = context.read<WorkoutsCubit>();
    final s = cubit.state;
    if (s.customWorkouts.isEmpty && s.customStatus != LoadStatus.loading) {
      cubit.loadCustomWorkouts();
    }
    if (s.exploreWorkouts.isEmpty && s.exploreStatus != LoadStatus.loading) {
      cubit.loadPublicWorkouts();
    }
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
    _debounce = Timer(const Duration(milliseconds: 450), _searchExplore);
  }

  void _searchExplore() {
    if (!mounted) return;
    setState(() => _visibleTemplates = _pageSize);
    context.read<WorkoutsCubit>().loadPublicWorkouts(
          query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          sortBy: _sortBy == 'newest' ? null : _sortBy,
        );
  }

  Future<void> _refreshAll() async {
    final cubit = context.read<WorkoutsCubit>();
    await Future.wait([
      cubit.loadCustomWorkouts(),
      cubit.loadPublicWorkouts(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        sortBy: _sortBy == 'newest' ? null : _sortBy,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, state) {
        final myLoading = state.customStatus == LoadStatus.loading && state.customWorkouts.isEmpty;
        final exploreLoading = state.exploreStatus == LoadStatus.loading && state.exploreWorkouts.isEmpty;
        final myError = state.customError;
        final exploreError = state.exploreError;
        final myWorkouts = state.customWorkouts;
        final templates = state.exploreWorkouts;
        final visibleTemplates = templates.take(_visibleTemplates).toList();
        final hasMore = templates.length > _visibleTemplates;

        if (myLoading && exploreLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }

        return RefreshIndicator(
          onRefresh: _refreshAll,
          color: AppColors.primaryGreen,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () async {
                        final result = await context.push(AppRoutes.createCustomWorkout);
                        if (context.mounted && result == true) {
                          context.read<WorkoutsCubit>().loadCustomWorkouts();
                        }
                      },
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Tạo workout', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                sliver: SliverToBoxAdapter(child: WorkoutSectionHeader(title: 'Workout của tôi')),
              ),
              if (myError != null && myWorkouts.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _InlineError(message: myError, onRetry: () => context.read<WorkoutsCubit>().loadCustomWorkouts()),
                  ),
                )
              else if (myWorkouts.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: WorkoutEmptyState(
                      title: 'Chưa có workout nào',
                      subtitle: 'Tạo lộ trình riêng và lên lịch tập theo tuần.',
                      actionLabel: 'Tạo workout đầu tiên',
                      onAction: () async {
                        final result = await context.push(AppRoutes.createCustomWorkout);
                        if (context.mounted && result == true) {
                          context.read<WorkoutsCubit>().loadCustomWorkouts();
                        }
                      },
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final w = myWorkouts[i];
                        return Padding(
                          padding: EdgeInsets.only(bottom: i == myWorkouts.length - 1 ? 0 : 16),
                          child: WorkoutListCard(
                            workout: w,
                            sessions: state.customSessions[w.id] ?? const [],
                            onTap: () async {
                              await context.push(AppRoutes.customWorkoutDetail(w.id));
                              if (context.mounted) {
                                context.read<WorkoutsCubit>().loadCustomWorkouts();
                              }
                            },
                            onDelete: () => _confirmDeleteWorkout(context, w),
                          ),
                        );
                      },
                      childCount: myWorkouts.length,
                    ),
                  ),
                ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(child: WorkoutBannerCarousel()),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
                sliver: SliverToBoxAdapter(child: WorkoutSectionHeader(title: 'Khám phá')),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchExplore(),
                    decoration: InputDecoration(
                      hintText: 'Tìm workout cộng đồng…',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward, color: AppColors.primaryGreen),
                        onPressed: _searchExplore,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        FilterChip(
                          label: const Text('Mới nhất'),
                          selected: _sortBy == 'newest',
                          onSelected: (_) {
                            setState(() => _sortBy = 'newest');
                            _searchExplore();
                          },
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _sortBy == 'newest' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.border.withValues(alpha: 0.4),
                          showCheckmark: false,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Lưu nhiều nhất'),
                          selected: _sortBy == 'saves',
                          onSelected: (_) {
                            setState(() => _sortBy = 'saves');
                            _searchExplore();
                          },
                          selectedColor: AppColors.primaryGreen,
                          labelStyle: TextStyle(
                            color: _sortBy == 'saves' ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          backgroundColor: AppColors.border.withValues(alpha: 0.4),
                          showCheckmark: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (exploreLoading)
                const SliverPadding(
                  padding: EdgeInsets.all(32),
                  sliver: SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
                  ),
                )
              else if (exploreError != null && templates.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: _InlineError(message: exploreError, onRetry: _searchExplore),
                  ),
                )
              else if (templates.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'Chưa có template cộng đồng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => WorkoutTemplateCard(
                        workout: visibleTemplates[i],
                        onSave: () => context.read<WorkoutsCubit>().clonePublicWorkout(visibleTemplates[i].id),
                      ),
                      childCount: visibleTemplates.length,
                    ),
                  ),
                ),
              if (hasMore)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _visibleTemplates += _pageSize),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Xem thêm', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                )
              else
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        );
      },
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

void _confirmDeleteWorkout(BuildContext context, UserCustomWorkout workout) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Xóa lộ trình?', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Bạn có chắc muốn xóa "${workout.workoutName}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Hủy')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<WorkoutsCubit>().deleteCustomWorkout(workout.id);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('Xóa', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
