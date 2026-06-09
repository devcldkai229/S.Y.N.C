import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final workout = await _repository.getCustomWorkoutById(widget.workoutId);
      final sessions = await _repository.getSessionsByRoadmap(widget.workoutId);
      final detail = await _repository.getCustomWorkoutDetail(widget.workoutId);

      setState(() {
        _workout = workout;
        _sessions = sessions;
        _workoutDetail = detail;
        _loading = false;
      });
    } catch (e) {
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
                        
                        setState(() {
                          _loading = true;
                        });
                        
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

  String _formatTimeRange(DateTime start, DateTime end) {
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$startStr - $endStr';
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
                          
                          setState(() {
                            _loading = true;
                          });
                          
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
      backgroundColor: const Color(0xFFF8F9FA), // Clean premium background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(_isModified),
        ),
        title: Text(
          _workout?.workoutName ?? 'Chi tiết lộ trình',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.textPrimary, size: 20),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    final workout = _workout;
    if (workout == null) {
      return const Center(child: Text('Lộ trình không tìm thấy.'));
    }

    final totalExercisesCount = _sessions.fold(0, (sum, s) => sum + s.exerciseCount);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primaryGreen,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Tags row
                Row(
                  children: [
                    _buildTag(workout.scheduleMode == 'Fixed' ? 'Fixed Schedule' : 'Flexible Schedule', color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    _buildTag('AI Optimization: ${workout.allowAiOptimization ? 'On' : 'Off'}', color: AppColors.primaryGreen),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                Text(
                  'Workout tự tạo để tăng cơ với lịch tập ${_sessions.length} buổi/tuần.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),

                // Summaries row (sessions + exercises count)
                Row(
                  children: [
                    _buildSummaryPill(Icons.calendar_today_outlined, '${_sessions.length} sessions'),
                    const SizedBox(width: 12),
                    _buildSummaryPill(Icons.fitness_center_outlined, '$totalExercisesCount exercises'),
                  ],
                ),
                const SizedBox(height: 24),

                // Schedule list (Lịch tập tuần này)
                const Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textPrimary),
                    SizedBox(width: 8),
                    Text(
                      'Lịch tập tuần này',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (workout.scheduleMode == 'Flexible' && (_workoutDetail?.weeklySchedules.isEmpty ?? true))
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 40,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Linh hoạt · chưa chọn lịch tuần này',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Thiết lập ngày và giờ tập cho các buổi tập tuần này để nhận thông báo nhắc nhở và quản lý tốt hơn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showQuickScheduleSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Chọn lịch tuần này',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_workoutDetail?.weeklySchedules.isNotEmpty == true)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _workoutDetail!.weeklySchedules.length,
                      separatorBuilder: (_, index) => const Divider(height: 1, color: Color(0xFFF1F3F5)),
                      itemBuilder: (context, index) {
                        final s = _workoutDetail!.weeklySchedules[index];
                        final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red, Colors.teal];
                        final activeColor = colors[index % colors.length];

                        return InkWell(
                          onTap: () async {
                            final res = await context.push(AppRoutes.customSessionDetail(s.sessionId));
                            if (context.mounted && res == true) {
                              _load();
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: activeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.fitness_center, color: activeColor, size: 16),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    s.sessionTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  '${_getWeekdayAbbr(s.scheduledStartTime)}  -  ${_formatTimeRange(s.scheduledStartTime, s.scheduledEndTime)}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE9ECEF)),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Chưa có lịch tập nào được ghi nhận.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                const SizedBox(height: 24),

                // Sessions List (Các buổi tập)
                const Text(
                  'Các buổi tập',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final s = _sessions[index];
                    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple, Colors.red, Colors.teal];
                    final activeColor = colors[index % colors.length];
                    final setsCount = s.executionBlocks.fold(0, (sum, b) => sum + b.targetSets);

                    return InkWell(
                      onTap: () async {
                        final res = await context.push(AppRoutes.customSessionDetail(s.id));
                        if (context.mounted && res == true) {
                          _load();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: activeColor.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.fitness_center, color: activeColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.sessionTitle,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${s.exerciseCount} exercises  •  $setsCount sets',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom Actions (2 Rows: Share/Edit, then full-width CTA)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showEditWorkoutModal,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                  label: const Text('Chỉnh sửa', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _sessions.isNotEmpty
                      ? () async {
                          final res = await context.push(AppRoutes.customSessionDetail(_sessions.first.id));
                          if (context.mounted && res == true) {
                            setState(() {
                              _isModified = true;
                            });
                            _load();
                          }
                        }
                      : null,
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  label: const Text(
                    'Bắt đầu buổi gần nhất',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String label, {Color? color}) {
    final displayColor = color ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: displayColor,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _getWeekdayAbbr(DateTime date) {
    const weekdayAbbr = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final idx = date.weekday - 1;
    if (idx >= 0 && idx < weekdayAbbr.length) {
      return weekdayAbbr[idx];
    }
    return '';
  }
}
