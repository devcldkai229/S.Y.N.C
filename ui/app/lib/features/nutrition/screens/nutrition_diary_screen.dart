import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/nutrition/cubit/nutrition_diary_cubit.dart';
import 'package:sync_app/features/nutrition/state/nutrition_refresh_notifier.dart';
import 'package:sync_app/features/nutrition/models/nutrition_models.dart';
import 'package:sync_app/features/nutrition/theme/nutrition_theme.dart';
import 'package:sync_app/features/nutrition/widgets/calorie_ring.dart';
import 'package:sync_app/features/nutrition/widgets/macro_bar.dart';
import 'package:sync_app/features/nutrition/widgets/meal_section_card.dart';
import 'package:sync_app/features/nutrition/widgets/water_tracker.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';
import 'package:sync_app/shared/widgets/sync_shimmer_box.dart';

class NutritionDiaryScreen extends StatelessWidget {
  const NutritionDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NutritionDiaryCubit(getIt())..load(),
      child: const AppShellOverlayScaffold(child: _NutritionDiaryView()),
    );
  }
}

class _NutritionDiaryView extends StatefulWidget {
  const _NutritionDiaryView();

  @override
  State<_NutritionDiaryView> createState() => _NutritionDiaryViewState();
}

class _NutritionDiaryViewState extends State<_NutritionDiaryView> {
  @override
  void initState() {
    super.initState();
    getIt<NutritionRefreshNotifier>().addListener(_onNutritionRefresh);
  }

  @override
  void dispose() {
    getIt<NutritionRefreshNotifier>().removeListener(_onNutritionRefresh);
    super.dispose();
  }

  void _onNutritionRefresh() {
    if (!mounted) return;
    final changed = getIt<NutritionRefreshNotifier>().lastChangedDate;
    if (changed == null) return;
    context.read<NutritionDiaryCubit>().refreshAfterMealLogged(date: changed);
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NutritionDiaryCubit, NutritionDiaryState>(
      builder: (context, state) {
        final cubit = context.read<NutritionDiaryCubit>();
        final summary = state.summary;
        final isLoading = state.status == NutritionDiaryStatus.loading && summary == null;

        return Scaffold(
          backgroundColor: NutritionTheme.background,
          appBar: AppBar(
            backgroundColor: NutritionTheme.background,
            elevation: 0,
            title: const Text('Nhật ký dinh dưỡng', style: TextStyle(color: NutritionTheme.heading)),
            centerTitle: true,
          ),
          body: RefreshIndicator(
            onRefresh: () => cubit.load(),
            child: isLoading
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SyncShimmerBox(height: 48),
                      SizedBox(height: 16),
                      SyncShimmerBox(height: 200),
                      SizedBox(height: 16),
                      SyncShimmerBox(height: 120),
                    ],
                  )
                : state.status == NutritionDiaryStatus.error && summary == null
                    ? _ErrorBody(message: state.errorMessage, onRetry: () => cubit.load())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        children: [
                          _DatePicker(
                            date: state.selectedDate,
                            isToday: _isToday(state.selectedDate),
                            onPrev: () => cubit.shiftDay(-1),
                            onNext: () => cubit.shiftDay(1),
                          ),
                          const SizedBox(height: 16),
                          if (summary != null) ...[
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: NutritionTheme.cardDecoration(),
                              child: Column(
                                children: [
                                  CalorieRing(
                                    remaining: summary.remainingCalories,
                                    consumed: summary.consumedCalories,
                                    target: summary.targetCalories,
                                    isOver: summary.isOverBudget,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    summary.isOverBudget
                                        ? 'Đã vượt nhẹ — mai tiếp tục nhé 💪'
                                        : 'Bạn còn ${summary.remainingCalories} kcal hôm nay 💪',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: summary.isOverBudget
                                          ? NutritionTheme.amberSoft
                                          : NutritionTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Đã nạp ${summary.consumedCalories} · Mục tiêu ${summary.targetCalories}',
                                    style: const TextStyle(fontSize: 13, color: NutritionTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                MacroBar(
                                  label: 'Đạm',
                                  consumed: summary.consumedProteinGram,
                                  target: summary.targetProteinGram,
                                  color: NutritionTheme.protein,
                                ),
                                const SizedBox(width: 12),
                                MacroBar(
                                  label: 'Tinh bột',
                                  consumed: summary.consumedCarbGram,
                                  target: summary.targetCarbGram,
                                  color: NutritionTheme.carb,
                                ),
                                const SizedBox(width: 12),
                                MacroBar(
                                  label: 'Béo',
                                  consumed: summary.consumedFatGram,
                                  target: summary.targetFatGram,
                                  color: NutritionTheme.fat,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            WaterTracker(
                              intakeMl: summary.waterIntakeMl,
                              targetMl: 2000,
                              onAdd: cubit.addWater,
                            ),
                          ],
                          const SizedBox(height: 20),
                          MealSectionCard(
                            title: 'Bữa sáng',
                            icon: Icons.wb_sunny_outlined,
                            logs: cubit.logsForMeal('Breakfast'),
                            onAdd: () => context.push(AppRoutes.nutritionFoodSearch, extra: MealTypeUi.breakfast),
                            onDeleteLog: (log) => cubit.deleteMealLog(log.id),
                          ),
                          MealSectionCard(
                            title: 'Bữa trưa',
                            icon: Icons.lunch_dining_outlined,
                            logs: cubit.logsForMeal('Lunch'),
                            onAdd: () => context.push(AppRoutes.nutritionFoodSearch, extra: MealTypeUi.lunch),
                            onDeleteLog: (log) => cubit.deleteMealLog(log.id),
                          ),
                          MealSectionCard(
                            title: 'Bữa tối',
                            icon: Icons.nights_stay_outlined,
                            logs: cubit.logsForMeal('Dinner'),
                            onAdd: () => context.push(AppRoutes.nutritionFoodSearch, extra: MealTypeUi.dinner),
                            onDeleteLog: (log) => cubit.deleteMealLog(log.id),
                          ),
                          MealSectionCard(
                            title: 'Bữa phụ',
                            icon: Icons.cookie_outlined,
                            logs: cubit.logsForMeal('Snack'),
                            onAdd: () => context.push(AppRoutes.nutritionFoodSearch, extra: MealTypeUi.snack),
                            onDeleteLog: (log) => cubit.deleteMealLog(log.id),
                          ),
                        ],
                      ),
          ),
        );
      },
    );
  }
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.date,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = isToday ? 'Hôm nay' : DateFormat('dd/MM/yyyy').format(date);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tải được dữ liệu. Thử lại nhé.'),
            if (message != null) Text(message!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
