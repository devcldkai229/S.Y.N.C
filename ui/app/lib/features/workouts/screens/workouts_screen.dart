import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/workouts/cubit/workouts_cubit.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class WorkoutsScreen extends StatelessWidget {
  const WorkoutsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkoutsCubit(getIt())
        ..loadRoadmap()
        ..loadCustomWorkouts()
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.border,
                  child: Icon(Icons.person, size: 20, color: AppColors.textMuted),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'SYNC',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryGreen,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.smart_toy_outlined, color: AppColors.primaryGreen),
                ),
              ],
            ),
          ),
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
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                tabs: const [
                  Tab(text: 'AI Roadmap'),
                  Tab(text: 'My Workouts'),
                  Tab(text: 'Catalog'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _AiRoadmapTab(),
                _CustomWorkoutsTab(),
                _CatalogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<RoadmapSession> _sessionsThisWeek(List<RoadmapSession> sessions) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - DateTime.monday));
  final end = start.add(const Duration(days: 7));
  return sessions.where((s) {
    final d = s.scheduledDate.toLocal();
    return !d.isBefore(start) && d.isBefore(end);
  }).toList();
}

class _AiRoadmapTab extends StatelessWidget {
  const _AiRoadmapTab();

  int _progressPercent(List<RoadmapSession> sessions) {
    if (sessions.isEmpty) return 0;
    final done = sessions.where((s) => s.isCompleted).length;
    return ((done / sessions.length) * 100).round();
  }

  String _weekSubtitle(PersonalizedRoadmap r) {
    final weeks = DateTime.now().difference(r.startDate).inDays ~/ 7 + 1;
    final totalWeeks = r.expectedEndDate != null
        ? (r.expectedEndDate!.difference(r.startDate).inDays / 7).ceil().clamp(1, 52)
        : 6;
    return 'Week $weeks of $totalWeeks • ${r.fitnessGoal.isNotEmpty ? r.fitnessGoal : r.roadmapName}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, state) {
        if (state.roadmapStatus == LoadStatus.loading && state.roadmap == null) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (state.roadmapStatus == LoadStatus.failure && state.roadmap == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.roadmapError ?? 'Error', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => context.read<WorkoutsCubit>().loadRoadmap(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final roadmap = state.roadmap;
        if (roadmap == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No AI roadmap yet. Personalized roadmaps are created by SYNC AI — you cannot create them manually.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9)),
              ),
            ),
          );
        }

        final allSessions = state.sessions;
        final weekSessions = _sessionsThisWeek(allSessions);
        final recovery = state.recovery;
        final nextSession = weekSessions.cast<RoadmapSession?>().firstWhere(
              (s) => s != null && !s.isCompleted && !s.isInProgress,
              orElse: () => allSessions.cast<RoadmapSession?>().firstWhere(
                    (s) => s != null && !s.isCompleted && !s.isInProgress,
                    orElse: () => null,
                  ),
            );

        return RefreshIndicator(
          onRefresh: () => context.read<WorkoutsCubit>().loadRoadmap(),
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              const _AiManagedBanner(),
              const SizedBox(height: 12),
              _PhaseCard(
                phaseTitle: roadmap.currentPhase.isNotEmpty ? roadmap.currentPhase : roadmap.roadmapName,
                subtitle: _weekSubtitle(roadmap),
                progressPercent: _progressPercent(allSessions),
                weightLine: roadmap.targetWeightKg > 0
                    ? '${roadmap.currentWeightKg.toStringAsFixed(1)} kg → ${roadmap.targetWeightKg.toStringAsFixed(1)} kg'
                    : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _RecoveryMiniCard(
                      label: 'System Fatigue',
                      value: recovery?.systemFatigueLabel ?? '—',
                      icon: Icons.battery_charging_full_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RecoveryMiniCard(
                      label: 'Muscle Soreness',
                      value: recovery?.muscleSorenessLabel ?? '—',
                      icon: Icons.accessibility_new_outlined,
                    ),
                  ),
                ],
              ),
              if (recovery != null && recovery.recommendedTrainingIntensity.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.insights_outlined, color: AppColors.primaryGreen, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'AI recommends: ${recovery.recommendedTrainingIntensity} intensity',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                "This Week's Sessions",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (weekSessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('No sessions this week.', style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ...weekSessions.map((s) {
                  final isNext = nextSession?.id == s.id;
                  return _SessionTile(session: s, isNextUp: isNext);
                }),
              if (allSessions.length > weekSessions.length) ...[
                const SizedBox(height: 8),
                Text(
                  '+ ${allSessions.length - weekSessions.length} more sessions in your plan',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CustomWorkoutsTab extends StatelessWidget {
  const _CustomWorkoutsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, state) {
        if (state.customStatus == LoadStatus.loading && state.customWorkouts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
        }
        if (state.customStatus == LoadStatus.failure && state.customWorkouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(state.customError ?? 'Error', textAlign: TextAlign.center),
                TextButton(
                  onPressed: () => context.read<WorkoutsCubit>().loadCustomWorkouts(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final workouts = state.customWorkouts;

        return RefreshIndicator(
          onRefresh: () => context.read<WorkoutsCubit>().loadCustomWorkouts(),
          color: AppColors.primaryGreen,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note_rounded, color: AppColors.primaryGreen),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Templates you create. Schedule them into your calendar from the web or future mobile flow.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (workouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No custom workouts yet.\nCreate one via POST /workouts/custom.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...workouts.map((w) => _CustomWorkoutCard(workout: w)),
            ],
          ),
        );
      },
    );
  }
}

class _CatalogTab extends StatefulWidget {
  const _CatalogTab();

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  final _searchController = TextEditingController();
  String _category = 'All';

  static const _categories = ['All', 'Strength', 'Cardio'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load(BuildContext context) {
    context.read<WorkoutsCubit>().loadCatalog(
          query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
          category: _category,
        );
  }

  Map<String, List<ExerciseCatalogItem>> _grouped(List<ExerciseCatalogItem> exercises) {
    final map = <String, List<ExerciseCatalogItem>>{};
    for (final e in exercises) {
      map.putIfAbsent(e.patternGroupTitle, () => []).add(e);
    }
    return map;
  }

  void _openDetail(BuildContext context, ExerciseCatalogItem exercise) {
    context.push(AppRoutes.exerciseDetail(exercise.id), extra: exercise);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutsCubit, WorkoutsState>(
      builder: (context, state) {
        final exercises = state.exercises;
        final featured = exercises.isNotEmpty ? exercises.first : null;
        final loading = state.catalogStatus == LoadStatus.loading && exercises.isEmpty;
        final error = state.catalogError;
        final grouped = _grouped(exercises);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _load(context),
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: AppColors.textMuted),
                    onPressed: () => _load(context),
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
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _categories[i];
                  final selected = c == _category;
                  return FilterChip(
                    label: Text(c == 'All' ? 'All Categories' : c),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _category = c);
                      _load(context);
                    },
                    selectedColor: AppColors.primaryGreen,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    backgroundColor: AppColors.border.withValues(alpha: 0.4),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                  : error != null && exercises.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(error, textAlign: TextAlign.center),
                              TextButton(onPressed: () => _load(context), child: const Text('Retry')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async => _load(context),
                          color: AppColors.primaryGreen,
                          child: ListView(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            children: [
                              if (featured != null)
                                _AiFeaturedCard(
                                  exercise: featured,
                                  onTap: () => _openDetail(context, featured),
                                ),
                              const SizedBox(height: 16),
                              ...grouped.entries.map(
                                (e) => _ExerciseGroup(
                                  title: e.key,
                                  items: e.value,
                                  onTapExercise: (ex) => _openDetail(context, ex),
                                ),
                              ),
                              if (exercises.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'No exercises found.',
                                      style: TextStyle(color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _AiManagedBanner extends StatelessWidget {
  const _AiManagedBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryGreen.withValues(alpha: 0.15),
            AppColors.lightGreen.withValues(alpha: 0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'AI-managed roadmap — sessions are generated and adjusted by SYNC AI.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCard extends StatelessWidget {
  const _PhaseCard({
    required this.phaseTitle,
    required this.subtitle,
    required this.progressPercent,
    this.weightLine,
  });

  final String phaseTitle;
  final String subtitle;
  final int progressPercent;
  final String? weightLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT PHASE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(phaseTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                if (weightLine != null) ...[
                  const SizedBox(height: 6),
                  Text(weightLine!, style: const TextStyle(fontSize: 12, color: AppColors.primaryGreen, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progressPercent / 100,
                  strokeWidth: 5,
                  backgroundColor: AppColors.border,
                  color: AppColors.primaryGreen,
                ),
                Text('$progressPercent%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryMiniCard extends StatelessWidget {
  const _RecoveryMiniCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primaryGreen),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.isNextUp});

  final RoadmapSession session;
  final bool isNextUp;

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[session.scheduledDate.toLocal().weekday - 1];
    final completed = session.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isNextUp ? AppColors.primaryGreen.withValues(alpha: 0.08) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNextUp ? AppColors.primaryGreen.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle_outline
                : isNextUp
                    ? Icons.play_circle_fill
                    : Icons.calendar_today_outlined,
            color: completed
                ? AppColors.textMuted
                : isNextUp
                    ? AppColors.primaryGreen
                    : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isNextUp)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Text(
                          'NEXT UP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    if (session.aiGenerated)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primaryGreen),
                        ),
                      ),
                  ],
                ),
                Text(
                  session.sessionTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: completed ? TextDecoration.lineThrough : null,
                    color: completed ? AppColors.textMuted : AppColors.textPrimary,
                  ),
                ),
                Text(
                  session.subtitleLine,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isNextUp)
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Start'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                completed ? 'Done $day' : day,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomWorkoutCard extends StatelessWidget {
  const _CustomWorkoutCard({required this.workout});

  final UserCustomWorkout workout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(workout.workoutName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              if (workout.allowAiOptimization)
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryGreen),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${workout.exerciseCount} exercises • ${workout.totalSets} sets • ${workout.scheduleMode.isNotEmpty ? workout.scheduleMode : workout.visibility}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (workout.blocks.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...workout.blocks.take(3).map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${b.summary} (${b.restSeconds}s rest)',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
                ),
            if (workout.blocks.length > 3)
              Text('+ ${workout.blocks.length - 3} more', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _AiFeaturedCard extends StatelessWidget {
  const _AiFeaturedCard({required this.exercise, required this.onTap});

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final desc = exercise.aiCoachingCues.isNotEmpty
        ? exercise.aiCoachingCues.first
        : 'Recommended for your current training block.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI RECOMMENDED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.primaryGreen.withValues(alpha: 0.15),
          ),
          child: Stack(
            children: [
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Icon(Icons.fitness_center, size: 64, color: AppColors.primaryGreen.withValues(alpha: 0.5)),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Tag(exercise.exerciseCode),
                        const SizedBox(width: 6),
                        _Tag('${exercise.metValue} MET'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.nameEn,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
          ),
        ),
      ],
    );
  }
}

class _ExerciseGroup extends StatelessWidget {
  const _ExerciseGroup({
    required this.title,
    required this.items,
    required this.onTapExercise,
  });

  final String title;
  final List<ExerciseCatalogItem> items;
  final void Function(ExerciseCatalogItem) onTapExercise;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 8),
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
        ...items.map((e) => _ExerciseListTile(exercise: e, onTap: () => onTapExercise(e))),
      ],
    );
  }
}

class _ExerciseListTile extends StatelessWidget {
  const _ExerciseListTile({required this.exercise, required this.onTap});

  final ExerciseCatalogItem exercise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final diff = exercise.difficulty.toUpperCase();
    Color diffColor = AppColors.primaryGreen;
    if (diff.contains('ADVANCED')) diffColor = Colors.red.shade400;
    if (diff.contains('INTERMEDIATE')) diffColor = AppColors.brightGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fitness_center, color: AppColors.primaryGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.nameEn, style: const TextStyle(fontWeight: FontWeight.w700)),
                  if (exercise.nameVi.isNotEmpty)
                    Text(exercise.nameVi, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text(
                    exercise.musclesEquipmentLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          diff,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: diffColor),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '~${exercise.estimatedCaloriesPerMinute} kcal/min',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (exercise.aiCoachingCues.isNotEmpty)
              const Icon(Icons.smart_toy_outlined, size: 18, color: AppColors.primaryGreen),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
