import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/workouts/cubit/workouts_cubit.dart';
import 'package:sync_app/features/workouts/widgets/ai_roadmap/ai_roadmap_tab_view.dart';
import 'package:sync_app/features/workouts/widgets/exercise_catalog/catalog_tab_view.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workouts_merged_tab.dart';
import 'package:sync_app/shared/widgets/sync_app_bar.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkoutsCubit(getIt())
        ..loadCustomWorkouts()
        ..loadPublicWorkouts()
        ..loadCatalog(),
      child: const _WorkoutsView(),
    );
  }
}

class _WorkoutsView extends StatefulWidget {
  const _WorkoutsView();

  @override
  State<_WorkoutsView> createState() => _WorkoutsViewState();
}

class _WorkoutsViewState extends State<_WorkoutsView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
    if (!_tabController.indexIsChanging) {
      _handleTabSelection();
    }
  }

  void _handleTabSelection() {
    final cubit = context.read<WorkoutsCubit>();
    switch (_tabController.index) {
      case 0:
        break;
      case 1:
        cubit.loadCustomWorkouts();
        cubit.loadPublicWorkouts();
        break;
      case 2:
        cubit.loadCatalog();
        break;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SyncAppBar(),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Workouts',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.28),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  tabs: const [
                    Tab(text: 'AI Roadmap'),
                    Tab(text: 'Workouts'),
                    Tab(text: 'Catalog'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  AiRoadmapTabView(),
                  WorkoutsMergedTab(),
                  CatalogTabView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
