import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/utils/workout_assets.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';

class CustomWorkoutDetailScreen extends StatefulWidget {
  const CustomWorkoutDetailScreen({
    super.key,
    required this.workoutId,
  });

  final String workoutId;

  @override
  State<CustomWorkoutDetailScreen> createState() => _CustomWorkoutDetailScreenState();
}

class _CustomWorkoutDetailScreenState extends State<CustomWorkoutDetailScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();

  UserCustomWorkout? _workout;
  MyWorkoutDetail? _workoutDetail;
  List<RoadmapSession> _sessions = [];
  bool _loading = true;
  String? _error;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _calculateDateTimeOffset(String weekdayLabel, String timeStr) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    int targetWeekdayOffset = 0;
    switch (weekdayLabel) {
      case 'T2': targetWeekdayOffset = 0; break;
      case 'T3': targetWeekdayOffset = 1; break;
      case 'T4': targetWeekdayOffset = 2; break;
      case 'T5': targetWeekdayOffset = 3; break;
      case 'T6': targetWeekdayOffset = 4; break;
      case 'T7': targetWeekdayOffset = 5; break;
      case 'CN': targetWeekdayOffset = 6; break;
    }
    final targetDate = monday.add(Duration(days: targetWeekdayOffset));
    final timeParts = timeStr.split(':');
    final hour = timeParts.isNotEmpty ? (int.tryParse(timeParts[0]) ?? 0) : 0;
    final minute = timeParts.length > 1 ? (int.tryParse(timeParts[1]) ?? 0) : 0;
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      hour,
      minute,
    );
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final workout = await _repository.getCustomWorkoutById(widget.workoutId);
      final sessions = await _repository.getSessionsByRoadmap(widget.workoutId);
      final detail = await _repository.getCustomWorkoutDetail(widget.workoutId);

      if (!mounted) return;
      setState(() {
        _workout = workout;
        _sessions = sessions;
        _workoutDetail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapApiError(e);
        _loading = false;
      });
    }
  }

  void _showEditWorkoutModal() {
    if (_workout == null) return;
    
    final nameController = TextEditingController(text: _workout!.workoutName);
    String scheduleMode = _workout!.scheduleMode.isNotEmpty ? _workout!.scheduleMode : 'Fixed';
    String visibility = _workout!.visibility.isNotEmpty ? _workout!.visibility : 'Private';
    bool allowAiOptimization = _workout!.allowAiOptimization;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Chỉnh sửa lộ trình',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Tên lộ trình',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Push Pull Legs',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lịch trình',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      scheduleMode == 'Fixed' ? 'Cố định (Fixed)' : 'Linh hoạt (Flexible)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quyền riêng tư',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Riêng tư (Private)')),
                          selected: visibility == 'Private',
                          selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: visibility == 'Private' ? AppColors.primaryGreen : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => visibility = 'Private');
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Công khai (Public)')),
                          selected: visibility == 'Public',
                          selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: visibility == 'Public' ? AppColors.primaryGreen : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() => visibility = 'Public');
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text(
                      'Tối ưu hóa bằng AI (AI Optimization)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Cho phép AI đề xuất và điều chỉnh set tập dựa trên mức độ hồi phục',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    value: allowAiOptimization,
                    activeThumbColor: AppColors.primaryGreen,
                    onChanged: (val) {
                      setModalState(() => allowAiOptimization = val);
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        
                        Navigator.pop(context); // close sheet

                        if (!mounted) return;
                        setState(() => _loading = true);

                        try {
                          final payload = {
                            'workoutName': name,
                            'scheduleMode': scheduleMode,
                            'visibility': visibility,
                            'allowAiOptimization': allowAiOptimization,
                            'customBlocks': _workout!.blocks.map((b) => {
                              'exerciseId': b.exerciseId,
                              'sets': b.sets,
                              'reps': b.reps,
                              'weightKg': b.weightKg,
                              'restSeconds': b.restSeconds,
                            }).toList(),
                          };
                          
                          await _repository.updateCustomWorkout(_workout!.id, payload);
                          _isModified = true;
                          await _load();
                        } catch (e) {
                          if (!mounted) return;
                          setState(() {
                            _error = mapApiError(e);
                            _loading = false;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lưu thay đổi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickScheduleSheet() {
    final defaultDays = ['T2', 'T4', 'T6', 'CN', 'T3', 'T5', 'T7'];
    final List<Map<String, dynamic>> tempSchedules = [];
    for (int i = 0; i < _sessions.length; i++) {
      final s = _sessions[i];
      tempSchedules.add({
        'sessionId': s.id,
        'sessionTitle': s.sessionTitle,
        'estimatedDurationMinutes': s.estimatedDurationMinutes,
        'weekday': defaultDays[i % defaultDays.length],
        'startTime': '19:00',
        'endTime': '20:00',
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Chọn lịch tuần này',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...tempSchedules.asMap().entries.map((entry) {
                      final sched = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sched['sessionTitle'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Ngày tập trong tuần',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(7, (dayIdx) {
                                final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                                final dayName = dayNames[dayIdx];
                                final isSelected = sched['weekday'] == dayName;
                                return GestureDetector(
                                  onTap: () {
                                    setModalState(() {
                                      sched['weekday'] = dayName;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? AppColors.primaryGreen : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      dayName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final parts = sched['startTime'].split(':');
                                      final hour = int.tryParse(parts[0]) ?? 19;
                                      final minute = int.tryParse(parts[1]) ?? 0;
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(hour: hour, minute: minute),
                                      );
                                      if (time != null) {
                                        setModalState(() {
                                          sched['startTime'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Giờ bắt đầu',
                                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(sched['startTime'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final parts = sched['endTime'].split(':');
                                      final hour = int.tryParse(parts[0]) ?? 20;
                                      final minute = int.tryParse(parts[1]) ?? 0;
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay(hour: hour, minute: minute),
                                      );
                                      if (time != null) {
                                        setModalState(() {
                                          sched['endTime'] = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                        });
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Giờ kết thúc',
                                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textMuted),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(sched['endTime'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // Close sheet

                          if (!mounted) return;
                          setState(() => _loading = true);

                          try {
                            for (final sched in tempSchedules) {
                              final startTime = _calculateDateTimeOffset(sched['weekday'], sched['startTime']);
                              final endTime = _calculateDateTimeOffset(sched['weekday'], sched['endTime']);
                              final scheduleBody = {
                                'sessionId': sched['sessionId'],
                                'scheduledStartTime': startTime.toUtc().toIso8601String(),
                                'scheduledEndTime': endTime.toUtc().toIso8601String(),
                                'repeatPattern': 'Weekly',
                                'status': 'Scheduled',
                              };
                              await _repository.createScheduledWorkout(scheduleBody);
                            }
                            await _load();
                          } catch (e) {
                            if (!mounted) return;
                            setState(() {
                              _error = mapApiError(e);
                              _loading = false;
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lập lịch tập',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutTheme.background,
      appBar: AppBar(
        backgroundColor: WorkoutTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: WorkoutTheme.textPrimary),
          onPressed: () => context.pop(_isModified),
        ),
        title: Text(
          _workout?.workoutName ?? 'Chi tiết lộ trình',
          style: const TextStyle(color: WorkoutTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: WorkoutTheme.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    final workout = _workout;
    if (workout == null) {
      return const Center(child: Text('Lộ trình không tìm thấy.'));
    }

    final totalExercisesCount = _sessions.fold(0, (sum, s) => sum + s.exerciseCount);
    final cover = WorkoutAssets.coverForWorkout(workout.workoutName);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: WorkoutTheme.primary,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                WorkoutHeroHeader(
                  title: workout.workoutName,
                  coverAsset: cover,
                  subtitle: 'Lộ trình tùy chỉnh · ${_sessions.length} buổi/tuần',
                  tags: [
                    WorkoutTagChip(label: workout.scheduleMode == 'Fixed' ? 'Cố định' : 'Linh hoạt'),
                    WorkoutTagChip(label: 'AI ${workout.allowAiOptimization ? 'On' : 'Off'}', color: WorkoutTheme.primary),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    WorkoutStatChip(icon: Icons.calendar_today_outlined, label: '${_sessions.length} buổi'),
                    WorkoutStatChip(icon: Icons.fitness_center_outlined, label: '$totalExercisesCount bài'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Lịch tập tuần này', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
                const SizedBox(height: 12),
                if (workout.scheduleMode == 'Flexible' && (_workoutDetail?.weeklySchedules.isEmpty ?? true))
                  WorkoutEmptyState(
                    title: 'Chưa lên lịch tuần này',
                    subtitle: 'Chọn ngày và giờ tập để nhận nhắc nhở.',
                    icon: Icons.event_available_outlined,
                    actionLabel: 'Lên lịch',
                    onAction: _showQuickScheduleSheet,
                  )
                else if (_workoutDetail?.weeklySchedules.isNotEmpty == true)
                  ..._workoutDetail!.weeklySchedules.map((s) {
                    final idx = _sessions.indexWhere((x) => x.id == s.sessionId);
                    final linked = idx >= 0 ? _sessions[idx] : null;
                    final exerciseCount = linked?.exerciseCount ?? 0;
                    final setCount = linked?.executionBlocks.fold<int>(0, (sum, b) => sum + b.targetSets) ?? 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SessionListCard(
                        title: s.sessionTitle,
                        exerciseCount: exerciseCount,
                        setCount: setCount,
                        thumbnailExerciseName: s.sessionTitle,
                        onTap: () async {
                          final res = await context.push(AppRoutes.customSessionDetail(s.sessionId));
                          if (mounted && res == true) await _load();
                        },
                      ),
                    );
                  })
                else
                  WorkoutEmptyState(
                    title: 'Chưa có lịch',
                    subtitle: 'Lên lịch các buổi tập của bạn.',
                    icon: Icons.calendar_month_outlined,
                    actionLabel: 'Lên lịch',
                    onAction: _showQuickScheduleSheet,
                  ),
                const SizedBox(height: 24),
                const Text('Các buổi tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
                const SizedBox(height: 12),
                ..._sessions.map((s) {
                  final sets = s.executionBlocks.fold(0, (sum, b) => sum + b.targetSets);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: SessionListCard(
                      title: s.sessionTitle,
                      exerciseCount: s.exerciseCount,
                      setCount: sets,
                      thumbnailExerciseName: s.executionBlocks.isNotEmpty ? s.executionBlocks.first.exerciseName : s.sessionTitle,
                      onTap: () async {
                        final res = await context.push(AppRoutes.customSessionDetail(s.id));
                        if (mounted && res == true) await _load();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        WorkoutStickyActions(
          secondaryLabel: 'Chỉnh sửa',
          onSecondary: _showEditWorkoutModal,
          primaryLabel: 'Bắt đầu buổi gần nhất',
          primaryEnabled: _sessions.isNotEmpty,
          onPrimary: _sessions.isEmpty
              ? null
              : () async {
                  final res = await context.push(AppRoutes.customSessionDetail(_sessions.first.id));
                  if (!mounted) return;
                  if (res == true) {
                    setState(() => _isModified = true);
                    await _load();
                  }
                },
        ),
      ],
    );
  }

}
