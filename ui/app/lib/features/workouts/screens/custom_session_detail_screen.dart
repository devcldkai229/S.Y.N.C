import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await _repository.getSessionById(widget.sessionId);
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = mapApiError(e);
        _loading = false;
      });
    }
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
      backgroundColor: const Color(0xFFF8F9FA), // Clean premium background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(_isModified),
        ),
        title: Text(
          _session?.sessionTitle ?? 'Chi tiết buổi tập',
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

    final session = _session;
    if (session == null) {
      return const Center(child: Text('Buổi tập không tìm thấy.'));
    }

    final totalSets = session.executionBlocks.fold(0, (sum, b) => sum + b.targetSets);

    return Column(
      children: [
        // Header metadata subtitle
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12, top: 4),
          child: Center(
            child: Text(
              '${session.estimatedDurationMinutes} phút  •  ${session.sessionType}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            color: AppColors.primaryGreen,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Summary pills row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _buildSummaryPill(Icons.timer_outlined, '${session.estimatedDurationMinutes} phút'),
                    const SizedBox(width: 8),
                    _buildSummaryPill(Icons.fitness_center_outlined, '${session.exerciseCount} exercises'),
                    const SizedBox(width: 8),
                    _buildSummaryPill(Icons.playlist_add_check_outlined, '$totalSets sets'),
                  ],
                ),
                const SizedBox(height: 20),

                // Exercises List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: session.executionBlocks.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final block = session.executionBlocks[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // 1. Order circle badge
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // 2. Exercise Image/Icon placeholder
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F3F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.fitness_center, color: AppColors.textMuted, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // 3. Exercise metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  block.exerciseName,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${block.targetSets} sets × ${block.targetReps} reps  •  ${block.targetWeightKg.toStringAsFixed(block.targetWeightKg.truncateToDouble() == block.targetWeightKg ? 0 : 1)} kg  •  Rest ${block.restSeconds}s',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // AI Note Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.15)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primaryGreen, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Note',
                              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primaryGreen, fontSize: 13),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tập trung vào kỹ thuật, không cần tăng tạ quá nhanh.',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Bottom Actions (Chỉnh sửa buổi tập, Start Workout)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _showEditSessionModal,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                  label: const Text('Chỉnh sửa buổi tập', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final res = await context.push(
                      AppRoutes.activeWorkout(session.id),
                      extra: session,
                    );
                    if (context.mounted && res == true) {
                      setState(() {
                        _isModified = true;
                      });
                      await _load();
                    }
                  },
                  icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                  label: const Text('Start Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
