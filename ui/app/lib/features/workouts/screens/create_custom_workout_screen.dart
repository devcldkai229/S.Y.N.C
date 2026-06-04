import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class CreateCustomWorkoutScreen extends StatefulWidget {
  const CreateCustomWorkoutScreen({super.key});

  @override
  State<CreateCustomWorkoutScreen> createState() => _CreateCustomWorkoutScreenState();
}

class _CreateCustomWorkoutScreenState extends State<CreateCustomWorkoutScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();

  int _currentStep = 0; // 0: Basic Info, 1: Schedule, 2: Sessions List, 3: Success
  int _editingSessionIndex = -1; // Index of session being designed/scheduled
  bool _isDesigningSession = false; // Sub-state to show Exercise Designer
  bool _isSchedulingSession = false; // Sub-state to show Session Scheduler
  bool _submitting = false;

  // Step 1: Basic Info
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _goal = 'Tăng cơ';
  String _visibility = 'Private';
  String _scheduleMode = 'Fixed';

  // Step 2: Schedule Config
  int _flexibleSessionCount = 3;

  // Step 3: Sessions List
  final List<_SessionData> _sessions = [];

  final List<String> _goals = ['Tăng cơ', 'Giảm mỡ', 'Duy trì', 'Tăng sức mạnh'];
  final List<String> _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _removeSession(int index) {
    setState(() {
      _sessions.removeAt(index);
    });
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

  Future<void> _submitCustomWorkout() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    for (final session in _sessions) {
      if (session.exercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buổi tập "${session.name}" phải có ít nhất 1 bài tập.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);

    try {
      // 1. Create UserCustomWorkout (overall roadmap metadata)
      final workoutBody = {
        'workoutName': name,
        'scheduleMode': _scheduleMode == 'Fixed' ? 'Fixed' : 'Flexible',
        'visibility': _visibility,
        'allowAiOptimization': true,
        'customBlocks': [], // Exercises will reside inside RoadmapSessions
      };

      final createdWorkout = await _repository.createCustomWorkout(workoutBody);
      final workoutId = createdWorkout.id;

      // 2. Loop and create each RoadmapSession & ScheduledWorkout
      for (final session in _sessions) {
        DateTime scheduledDateTime;
        if (_scheduleMode == 'Fixed') {
          scheduledDateTime = _calculateDateTimeOffset(session.scheduledWeekday, session.scheduledTime);
        } else {
          scheduledDateTime = DateTime.now();
        }

        final sessionBody = {
          'roadmapId': workoutId,
          'scheduledDate': scheduledDateTime.toUtc().toIso8601String(), // reference date
          'scheduledTime': session.scheduledTime,
          'timezone': 'Asia/Ho_Chi_Minh',
          'sessionType': 'Strength',
          'sessionTitle': session.name,
          'estimatedDurationMinutes': session.estimatedDuration,
          'energyDemandScore': 5,
          'recoveryRequirementScore': 5,
          'notificationEnabled': session.reminderEnabled,
          'notificationMinutesBefore': session.reminderMinutesBefore,
          'aiGenerated': false,
          'sessionStatus': 'Scheduled',
          'executionBlocks': session.exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final ex = entry.value;
            return {
              'order': idx + 1,
              'exerciseId': ex.exercise.id,
              'exerciseName': ex.exercise.nameEn,
              'targetSets': ex.sets,
              'targetReps': ex.reps,
              'targetWeightKg': ex.weightKg,
              'restSeconds': ex.restSeconds,
              'tempo': '3010',
              'exerciseNotes': ex.notes.isEmpty ? null : ex.notes
            };
          }).toList(),
        };

        // Create the session
        final sessionResult = await _repository.createRoadmapSession(sessionBody);
        final sessionId = sessionResult['id']?.toString();

        // 3. Create the schedule if Fixed mode and enabled
        if (_scheduleMode == 'Fixed' && sessionId != null && session.reminderEnabled) {
          final startTime = _calculateDateTimeOffset(session.scheduledWeekday, session.scheduledTime);
          final endTime = _calculateDateTimeOffset(session.scheduledWeekday, session.scheduledEndTime);
          final scheduleBody = {
            'sessionId': sessionId,
            'scheduledStartTime': startTime.toUtc().toIso8601String(),
            'scheduledEndTime': endTime.toUtc().toIso8601String(),
            'repeatPattern': 'Weekly',
            'status': 'Scheduled',
          };
          await _repository.createScheduledWorkout(scheduleBody);
        }
      }

      setState(() {
        _submitting = false;
        _currentStep = 3; // Go to success screen
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${mapApiError(e)}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên lộ trình')),
      );
      return;
    }
    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    setState(() {
      if (_currentStep > 0) _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesigningSession) {
      return _buildExerciseDesigner(_sessions[_editingSessionIndex]);
    }
    if (_isSchedulingSession) {
      return _buildSessionScheduler(_sessions[_editingSessionIndex]);
    }

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.cardBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                _currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: _currentStep == 0 ? () => context.pop() : _prevStep,
            ),
            title: Text(
              _currentStep == 3 ? 'Hoàn tất' : 'Tạo lộ trình mới',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: _buildCurrentStepView(),
        ),
        if (_submitting)
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case 0:
        return _buildStepBasicInfo();
      case 1:
        return _buildStepScheduleMode();
      case 2:
        return _buildStepSessionsList();
      case 3:
        return _buildStepSuccess();
      default:
        return const SizedBox.shrink();
    }
  }

  // STEP 1: Basic Info
  Widget _buildStepBasicInfo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Tạo lộ trình mới (Basic Info)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildTextField('Tên lộ trình *', _nameController, 'e.g., Push/Pull/Legs 4 buổi/tuần'),
        const SizedBox(height: 16),
        _buildGoalDropdown(),
        const SizedBox(height: 16),
        _buildVisibilitySelector(),
        const SizedBox(height: 24),
        _buildBottomButton('Tiếp tục', _nextStep),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          hintText: hint,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildGoalDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: DropdownButtonFormField<String>(
        initialValue: _goal,
        decoration: const InputDecoration(
          labelText: 'Mục tiêu *',
          labelStyle: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600),
          border: InputBorder.none,
        ),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
        items: _goals.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _goal = val);
        },
      ),
    );
  }

  Widget _buildVisibilitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Visibility *', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSelectableOption(
                  title: 'Public',
                  subtitle: 'Chia sẻ với cộng đồng',
                  selected: _visibility == 'Public',
                  onTap: () => setState(() => _visibility = 'Public'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSelectableOption(
                  title: 'Private',
                  subtitle: 'Chỉ mình bạn',
                  selected: _visibility == 'Private',
                  onTap: () => setState(() => _visibility = 'Private'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Schedule Mode *', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _buildSelectableOption(
            title: 'Cố định (theo lịch)',
            subtitle: 'Tập vào các ngày cố định trong tuần',
            selected: _scheduleMode == 'Fixed',
            onTap: () => setState(() => _scheduleMode = 'Fixed'),
          ),
          const SizedBox(height: 10),
          _buildSelectableOption(
            title: 'Linh hoạt',
            subtitle: 'Tự chọn ngày trong tuần để tập',
            selected: _scheduleMode == 'Flexible',
            onTap: () => setState(() => _scheduleMode = 'Flexible'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryGreen.withValues(alpha: 0.05) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primaryGreen : AppColors.border,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_off,
                  color: selected ? AppColors.primaryGreen : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // STEP 2: Choose Schedule
  Widget _buildStepScheduleMode() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Chế độ và số buổi tập',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildScheduleModeSelector(),
        const SizedBox(height: 20),
        const Text(
          'Số buổi / tuần',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _flexibleSessionCount > 1
                  ? () => setState(() => _flexibleSessionCount--)
                  : null,
              icon: const Icon(Icons.remove_circle_outline, size: 36, color: AppColors.primaryGreen),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '$_flexibleSessionCount',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: _flexibleSessionCount < 7
                  ? () => setState(() => _flexibleSessionCount++)
                  : null,
              icon: const Icon(Icons.add_circle_outline, size: 36, color: AppColors.primaryGreen),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            _scheduleMode == 'Fixed'
                ? 'Hệ thống sẽ lập lịch cố định hàng tuần'
                : 'Bạn sẽ tự chọn ngày tập mỗi tuần',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 32),
        _buildBottomButton('Tiếp tục', () {
          if (_sessions.length != _flexibleSessionCount) {
            _sessions.clear();
            List<String> defaultNames = [];
            if (_flexibleSessionCount == 4) {
              defaultNames = const ['Push Day', 'Pull Day', 'Legs Day', 'Upper Body'];
            } else if (_flexibleSessionCount == 3) {
              defaultNames = const ['Push Day', 'Pull Day', 'Legs Day'];
            } else {
              defaultNames = List.generate(_flexibleSessionCount, (idx) => 'Buổi ${idx + 1}');
            }
            List<String> defaultWeekdays = const ['T2', 'T4', 'T6', 'CN', 'T3', 'T5', 'T7'];
            for (int i = 0; i < _flexibleSessionCount; i++) {
              _sessions.add(
                _SessionData(
                  name: defaultNames[i],
                  estimatedDuration: 60,
                )..scheduledWeekday = defaultWeekdays[i % defaultWeekdays.length],
              );
            }
          }
          _nextStep();
        }),
      ],
    );
  }

  // STEP 3: Sessions List
  Widget _buildStepSessionsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _sessions.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (context, idx) {
              final s = _sessions[idx];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Buổi ${idx + 1}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primaryGreen),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fitness_center, color: AppColors.primaryGreen),
                              onPressed: () {
                                setState(() {
                                  _editingSessionIndex = idx;
                                  _isDesigningSession = true;
                                });
                              },
                              tooltip: 'Thiết kế bài tập',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _removeSession(idx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: s.name,
                      onChanged: (val) => s.name = val.trim(),
                      decoration: const InputDecoration(
                        labelText: 'Tên buổi tập',
                        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    if (_scheduleMode == 'Fixed') ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Ngày tập trong tuần',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (dayIdx) {
                          final dayName = _dayNames[dayIdx];
                          final isSelected = s.scheduledWeekday == dayName;
                          return GestureDetector(
                            onTap: () => setState(() => s.scheduledWeekday = dayName),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isSelected ? AppColors.primaryGreen : AppColors.border),
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
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final parts = s.scheduledTime.split(':');
                                final initialHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 19) : 19;
                                final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
                                );
                                if (time != null) {
                                  setState(() {
                                    s.scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Giờ bắt đầu',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: Text(s.scheduledTime, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final parts = s.scheduledEndTime.split(':');
                                final initialHour = parts.isNotEmpty ? (int.tryParse(parts[0]) ?? 20) : 20;
                                final initialMinute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
                                final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
                                );
                                if (time != null) {
                                  setState(() {
                                    s.scheduledEndTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Giờ kết thúc',
                                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                child: Text(s.scheduledEndTime, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Thiết lập: ${s.exercises.length} bài tập',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: AppColors.cardBackground,
          child: _buildBottomButton('Hoàn tất', _submitCustomWorkout),
        ),
      ],
    );
  }

  // STEP 4: Success & Share
  Widget _buildStepSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 80, color: AppColors.primaryGreen),
            const SizedBox(height: 24),
            const Text(
              'Lộ trình đã tạo thành công!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionIconButton(Icons.share, 'Chia sẻ'),
                const SizedBox(width: 20),
                _buildActionIconButton(Icons.link, 'Sao chép'),
                const SizedBox(width: 20),
                _buildActionIconButton(Icons.remove_red_eye_outlined, 'Xem trước'),
              ],
            ),
            const SizedBox(height: 48),
            _buildBottomButton('Quay về danh sách', () => Navigator.pop(context, true)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIconButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primaryGreen),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // SUB-SCREEN: Exercise Designer (ExecutionBlocks)
  Widget _buildExerciseDesigner(_SessionData session) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => setState(() => _isDesigningSession = false),
        ),
        title: Text('Chi tiết buổi tập - ${session.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (session.exercises.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: const Column(
                      children: [
                        Icon(Icons.fitness_center, size: 48, color: AppColors.textMuted),
                        SizedBox(height: 16),
                        Text('Chưa có bài tập nào được thêm', style: TextStyle(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: session.exercises.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final ex = session.exercises[idx];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(ex.exercise.nameEn, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () => setState(() => session.exercises.removeAt(idx)),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDetailControl('Sets', '${ex.sets}', () {
                                  if (ex.sets > 1) setState(() => ex.sets--);
                                }, () => setState(() => ex.sets++)),
                                _buildDetailControl('Reps', '${ex.reps}', () {
                                  if (ex.reps > 1) setState(() => ex.reps--);
                                }, () => setState(() => ex.reps++)),
                                _buildDetailControl('Rest', '${ex.restSeconds}s', () {
                                  if (ex.restSeconds > 15) setState(() => ex.restSeconds -= 15);
                                }, () => setState(() => ex.restSeconds += 15)),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.cardBackground,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final selected = await showModalBottomSheet<ExerciseCatalogItem>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => _SelectExerciseBottomSheet(repository: _repository),
                      );
                      if (selected != null) {
                        setState(() {
                          session.exercises.add(_ExerciseInput(exercise: selected));
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryGreen,
                      side: const BorderSide(color: AppColors.primaryGreen),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('+ Thêm bài tập', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _isDesigningSession = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Lưu buổi tập', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailControl(String label, String value, VoidCallback onDec, VoidCallback onInc) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.remove, size: 12), onPressed: onDec, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              IconButton(icon: const Icon(Icons.add, size: 12), onPressed: onInc, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
        ),
      ],
    );
  }

  // SUB-SCREEN: Session Scheduler (ScheduledWorkout)
  Widget _buildSessionScheduler(_SessionData session) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => setState(() => _isSchedulingSession = false),
        ),
        title: Text('Lập lịch - ${session.name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bật lịch', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Switch(
                      value: session.reminderEnabled,
                      activeThumbColor: AppColors.primaryGreen,
                      onChanged: (val) => setState(() => session.reminderEnabled = val),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thời gian bắt đầu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 19, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            session.scheduledTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: Text(session.scheduledTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Thời gian kết thúc (dự kiến)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    TextButton(
                      onPressed: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 20, minute: 0),
                        );
                        if (time != null) {
                          setState(() {
                            session.scheduledEndTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                          });
                        }
                      },
                      child: Text(session.scheduledEndTime, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Lặp lại', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const Text('Hàng tuần', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nhắc nhở', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text('Trước 15 phút', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildBottomButton('Lưu lịch', () => setState(() => _isSchedulingSession = false)),
        ],
      ),
    );
  }

  Widget _buildBottomButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ),
    );
  }
}

class _SessionData {
  _SessionData({
    required this.name,
    required this.estimatedDuration,
  });

  String name;
  int estimatedDuration;
  String scheduledTime = '19:00';
  String scheduledEndTime = '20:00';
  String scheduledWeekday = 'T2';
  bool reminderEnabled = true;
  int reminderMinutesBefore = 15;
  List<_ExerciseInput> exercises = [];
}

class _ExerciseInput {
  _ExerciseInput({
    required this.exercise,
  });

  final ExerciseCatalogItem exercise;
  int sets = 3;
  int reps = 10;
  double weightKg = 0.0;
  int restSeconds = 60;
  String notes = '';
}

class _SelectExerciseBottomSheet extends StatefulWidget {
  const _SelectExerciseBottomSheet({required this.repository});

  final WorkoutRepository repository;

  @override
  State<_SelectExerciseBottomSheet> createState() => _SelectExerciseBottomSheetState();
}

class _SelectExerciseBottomSheetState extends State<_SelectExerciseBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseCatalogItem> _exercises = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.repository.searchCatalog(
        query: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        category: 'All',
      );
      setState(() {
        _exercises = items;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = mapApiError(e);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75 + bottomInset,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Exercise',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _loadExercises(),
            decoration: InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _searchController.clear();
                        _loadExercises();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.primaryGreen),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search Results
          Expanded(
            child: _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading && _exercises.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }
    if (_error != null && _exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadExercises,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_exercises.isEmpty) {
      return const Center(
        child: Text(
          'No exercises found.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView.separated(
      itemCount: _exercises.length,
      separatorBuilder: (_, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final exercise = _exercises[i];
        final diff = exercise.difficulty.toUpperCase();
        Color diffColor = AppColors.primaryGreen;
        if (diff.contains('ADVANCED')) diffColor = Colors.red.shade400;
        if (diff.contains('INTERMEDIATE')) diffColor = AppColors.brightGreen;

        return InkWell(
          onTap: () => Navigator.pop(context, exercise),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppColors.primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.nameEn,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      if (exercise.nameVi.isNotEmpty)
                        Text(
                          exercise.nameVi,
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              diff,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: diffColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            exercise.category,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}
