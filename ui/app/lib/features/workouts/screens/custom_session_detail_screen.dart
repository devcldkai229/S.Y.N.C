import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';

class CustomSessionDetailScreen extends StatefulWidget {
  const CustomSessionDetailScreen({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<CustomSessionDetailScreen> createState() => _CustomSessionDetailScreenState();
}

class _CustomSessionDetailScreenState extends State<CustomSessionDetailScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();

  RoadmapSession? _session;
  bool _loading = true;
  String? _error;
  bool _isModified = false;
  int _visibleExerciseCount = 5;
  Map<String, String> _thumbnailUrls = {};
  bool _loadingThumbnails = false;

  static const _exercisePageSize = 5;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await _repository.getSessionById(widget.sessionId);
      if (!mounted) return;
      setState(() {
        _session = session;
        _loading = false;
        _visibleExerciseCount = session.executionBlocks.length <= 5
            ? session.executionBlocks.length
            : 5;
      });
      await _loadThumbnailsForVisible();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = mapApiError(e);
        _loading = false;
      });
    }
  }

  Future<void> _loadThumbnailsForVisible() async {
    final session = _session;
    if (session == null || session.executionBlocks.isEmpty) return;

    final blocks = session.executionBlocks.take(_visibleExerciseCount).toList();
    final missingIds = blocks
        .map((b) => b.exerciseId)
        .where((id) => id.isNotEmpty && !_thumbnailUrls.containsKey(id))
        .toList();
    if (missingIds.isEmpty) return;

    setState(() => _loadingThumbnails = true);
    try {
      final urls = await _repository.getExerciseThumbnailUrls(missingIds);
      if (!mounted) return;
      setState(() {
        _thumbnailUrls = {..._thumbnailUrls, ...urls};
        _loadingThumbnails = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingThumbnails = false);
    }
  }

  void _showMoreExercises(int total) {
    setState(() {
      _visibleExerciseCount = (_visibleExerciseCount + _exercisePageSize).clamp(0, total);
    });
    _loadThumbnailsForVisible();
  }

  void _showEditSessionModal() {
    if (_session == null) return;

    final titleController = TextEditingController(text: _session!.sessionTitle);
    final durationController = TextEditingController(text: _session!.estimatedDurationMinutes.toString());
    String sessionType = _session!.sessionType.isNotEmpty ? _session!.sessionType : 'Strength';
    
    // Copy the execution blocks so we can edit them
    final List<Map<String, dynamic>> blocksData = _session!.executionBlocks.map((b) {
      return {
        'order': b.order,
        'exerciseId': b.exerciseId,
        'exerciseName': b.exerciseName,
        'targetSets': b.targetSets,
        'targetReps': b.targetReps,
        'targetWeightKg': b.targetWeightKg,
        'restSeconds': b.restSeconds,
        'tempo': '3010',
        'exerciseNotes': b.exerciseNotes,
      };
    }).toList();

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
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75, // Allow scrollable sheet
                child: Column(
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
                        'Chỉnh sửa buổi tập',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tên buổi tập',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: titleController,
                              decoration: InputDecoration(
                                hintText: 'e.g., Push Day',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Thời gian (phút)',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: durationController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Loại buổi tập',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        initialValue: sessionType,
                                        items: const ['Strength', 'Cardio', 'Recovery', 'Mobility']
                                            .map((type) => DropdownMenuItem(
                                                  value: type,
                                                  child: Text(type),
                                                ))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setModalState(() => sessionType = val);
                                          }
                                        },
                                        decoration: InputDecoration(
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFE2E8F0)),
                            const SizedBox(height: 10),
                            const Text(
                              'Danh sách bài tập',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: blocksData.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 16),
                              itemBuilder: (context, idx) {
                                final block = blocksData[idx];
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FA),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${idx + 1}. ${block['exerciseName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Sets', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  initialValue: block['targetSets'].toString(),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) {
                                                    block['targetSets'] = int.tryParse(val) ?? 0;
                                                  },
                                                  decoration: const InputDecoration(
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Reps', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  initialValue: block['targetReps'].toString(),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) {
                                                    block['targetReps'] = int.tryParse(val) ?? 0;
                                                  },
                                                  decoration: const InputDecoration(
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Tạ (kg)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  initialValue: block['targetWeightKg'].toString(),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  onChanged: (val) {
                                                    block['targetWeightKg'] = double.tryParse(val) ?? 0.0;
                                                  },
                                                  decoration: const InputDecoration(
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Nghỉ (s)', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  initialValue: block['restSeconds'].toString(),
                                                  keyboardType: TextInputType.number,
                                                  onChanged: (val) {
                                                    block['restSeconds'] = int.tryParse(val) ?? 0;
                                                  },
                                                  decoration: const InputDecoration(
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                    isDense: true,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final durationStr = durationController.text.trim();
                          if (title.isEmpty || durationStr.isEmpty) return;

                          Navigator.pop(context); // Close modal

                          setState(() {
                            _loading = true;
                          });

                          try {
                            final payload = {
                              'roadmapId': _session!.roadmapId,
                              'scheduledDate': _session!.scheduledDate.toUtc().toIso8601String(),
                              'scheduledTime': _session!.scheduledTime,
                              'timezone': 'Asia/Ho_Chi_Minh',
                              'sessionType': sessionType,
                              'sessionTitle': title,
                              'estimatedDurationMinutes': int.tryParse(durationStr) ?? 45,
                              'energyDemandScore': 5,
                              'recoveryRequirementScore': 5,
                              'notificationEnabled': true,
                              'notificationMinutesBefore': 30,
                              'aiGenerated': _session!.aiGenerated,
                              'sessionStatus': _session!.sessionStatus,
                              'executionBlocks': blocksData,
                            };

                            await _repository.updateRoadmapSession(_session!.id, payload);
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
                          'Lưu buổi tập',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          _session?.sessionTitle ?? 'Chi tiết buổi tập',
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

    final session = _session;
    if (session == null) {
      return const Center(child: Text('Buổi tập không tìm thấy.'));
    }

    final totalSets = session.executionBlocks.fold(0, (sum, b) => sum + b.targetSets);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: WorkoutTheme.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                Text(
                  session.sessionTitle,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  '${session.estimatedDurationMinutes} phút · ${session.sessionType}',
                  style: const TextStyle(color: WorkoutTheme.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    WorkoutStatChip(icon: Icons.timer_outlined, label: '${session.estimatedDurationMinutes} phút'),
                    WorkoutStatChip(icon: Icons.fitness_center_outlined, label: '${session.exerciseCount} bài'),
                    WorkoutStatChip(icon: Icons.checklist_rounded, label: '$totalSets sets'),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Danh sách bài tập', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
                const SizedBox(height: 12),
                ...session.executionBlocks.take(_visibleExerciseCount).toList().asMap().entries.map((e) {
                  final block = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ExerciseListRow(
                      index: e.key + 1,
                      name: block.exerciseName,
                      sets: block.targetSets,
                      reps: block.targetReps,
                      weightKg: block.targetWeightKg,
                      restSeconds: block.restSeconds,
                      thumbnailUrl: _thumbnailUrls[block.exerciseId],
                      onTap: () => context.push(AppRoutes.exerciseDetail(block.exerciseId)),
                    ),
                  );
                }),
                if (_visibleExerciseCount < session.executionBlocks.length)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: _loadingThumbnails
                            ? null
                            : () => _showMoreExercises(session.executionBlocks.length),
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        label: Text(
                          'Xem thêm (${session.executionBlocks.length - _visibleExerciseCount} bài)',
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: WorkoutTheme.lime.withValues(alpha: 0.25),
                    borderRadius: WorkoutTheme.radiusMd,
                    border: Border.all(color: WorkoutTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: WorkoutTheme.primary, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Note', style: TextStyle(fontWeight: FontWeight.w900, color: WorkoutTheme.primary, fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              'Tập trung vào kỹ thuật, không cần tăng tạ quá nhanh.',
                              style: TextStyle(color: WorkoutTheme.textPrimary, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        WorkoutStickyActions(
          secondaryLabel: 'Chỉnh sửa buổi tập',
          onSecondary: _showEditSessionModal,
          primaryLabel: 'Start Workout',
          onPrimary: () async {
            final res = await context.push(AppRoutes.activeWorkout(session.id), extra: session);
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
