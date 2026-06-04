import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  const WorkoutExecutionScreen({
    super.key,
    required this.sessionId,
    this.initialSession,
  });

  final String sessionId;
  final RoadmapSession? initialSession;

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  final WorkoutRepository _repository = getIt<WorkoutRepository>();

  RoadmapSession? _session;
  String? _executionId;
  bool _loading = true;
  String? _error;

  // Active workout states
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0; // 0-indexed active set
  List<List<bool>> _completedSets = []; // outer index = exercise index, inner = set index
  int _workoutDurationSeconds = 0;
  Timer? _workoutTimer;

  // Rest timer states
  bool _isResting = false;
  int _restSecondsLeft = 0;
  int _restSecondsTotal = 0;
  Timer? _restTimer;

  // Completion states
  bool _isFinished = false;

  // Exercise Detail Cache
  final Map<String, ExerciseCatalogDetail> _exerciseDetails = {};
  bool _loadingDetails = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSession != null) {
      _session = widget.initialSession;
      _initWorkout();
    } else {
      _loadSession();
    }
  }

  @override
  void dispose() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final session = await _repository.getSessionById(widget.sessionId);
      setState(() {
        _session = session;
        _initWorkout();
      });
    } catch (e) {
      setState(() {
        _error = mapApiError(e);
        _loading = false;
      });
    }
  }

  void _initWorkout() {
    final session = _session;
    if (session == null) {
      setState(() => _loading = false);
      return;
    }

    // Initialize completion status matrix
    _completedSets = List.generate(
      session.executionBlocks.length,
      (i) => List.filled(session.executionBlocks[i].targetSets, false),
    );

    // Start workout elapsed timer
    _workoutDurationSeconds = 0;
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isResting && !_isFinished) {
        setState(() {
          _workoutDurationSeconds++;
        });
      }
    });

    setState(() {
      _currentExerciseIndex = 0;
      _currentSetIndex = 0;
      _isResting = false;
      _isFinished = false;
      _loading = false;
    });

    _onExerciseChanged();
    _startWorkoutExecution();
  }

  void _onExerciseChanged() {
    final session = _session;
    if (session == null) return;
    final block = session.executionBlocks[_currentExerciseIndex];
    _loadExerciseDetail(block.exerciseId);
  }

  Future<void> _loadExerciseDetail(String exerciseId) async {
    if (_exerciseDetails.containsKey(exerciseId)) return;
    setState(() => _loadingDetails = true);
    try {
      final detail = await _repository.getExerciseDetail(exerciseId);
      if (detail != null && mounted) {
        setState(() {
          _exerciseDetails[exerciseId] = detail;
          _loadingDetails = false;
        });
      } else {
        setState(() => _loadingDetails = false);
      }
    } catch (_) {
      setState(() => _loadingDetails = false);
    }
  }

  // Rest Timer Controller
  void _startRest(int seconds) {
    if (seconds <= 0) return;
    _restTimer?.cancel();

    setState(() {
      _isResting = true;
      _restSecondsTotal = seconds;
      _restSecondsLeft = seconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_restSecondsLeft <= 1) {
        _stopRest();
      } else {
        setState(() {
          _restSecondsLeft--;
        });
      }
    });
  }

  void _stopRest() {
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      // Advance to next set or exercise
      final session = _session!;
      final block = session.executionBlocks[_currentExerciseIndex];
      if (_currentSetIndex < block.targetSets - 1) {
        _currentSetIndex++;
      } else {
        if (_currentExerciseIndex < session.executionBlocks.length - 1) {
          _currentExerciseIndex++;
          _currentSetIndex = 0;
          _onExerciseChanged();
        } else {
          _finishWorkout();
        }
      }
    });
  }

  void _addRest30s() {
    setState(() {
      _restSecondsLeft += 30;
      _restSecondsTotal += 30;
    });
  }

  // Logging logic
  void _markCurrentSetComplete() {
    if (_isResting || _isFinished) return;

    final session = _session!;
    final block = session.executionBlocks[_currentExerciseIndex];

    setState(() {
      _completedSets[_currentExerciseIndex][_currentSetIndex] = true;

      // Log set to API
      _logSetComplete(block, _currentSetIndex + 1);

      // Check if this is the last set of the session
      final isLastSetOfExercise = _currentSetIndex == block.targetSets - 1;
      final isLastExercise = _currentExerciseIndex == session.executionBlocks.length - 1;

      if (isLastSetOfExercise && isLastExercise) {
        _finishWorkout();
      } else {
        // Start rest timer
        _startRest(block.restSeconds > 0 ? block.restSeconds : 60);
      }
    });
  }

  void _finishWorkout() {
    _workoutTimer?.cancel();
    _restTimer?.cancel();
    _submitFinishWorkout();
    setState(() {
      _isFinished = true;
      _isResting = false;
    });
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (_error != null || _session == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Không thể tải buổi tập', style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSession,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFinished) {
      return _buildFinishedView();
    }

    if (_isResting) {
      return _buildRestView();
    }

    return _buildActiveWorkoutView();
  }

  // 1. ACTIVE WORKOUT VIEW (REDESIGNED PREMIUM DARK MODE LAYOUT)
  Widget _buildActiveWorkoutView() {
    final session = _session!;
    final block = session.executionBlocks[_currentExerciseIndex];
    final detail = _exerciseDetails[block.exerciseId];

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep premium dark background
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 24),
          onPressed: () => _confirmExitWorkout(),
        ),
        title: Column(
          children: [
            Text(
              block.exerciseName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Set ${_currentSetIndex + 1} of ${block.targetSets}',
              style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Text(
                _formatDuration(_workoutDurationSeconds),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white, size: 20),
                onPressed: () => _confirmExitWorkout(),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  // CARD 1: WHITE ILLUSTRATION CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Left illustration side
                        Expanded(
                          flex: 5,
                          child: AspectRatio(
                            aspectRatio: 1.1,
                            child: _buildExerciseIllustration(detail),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right targeted muscles side
                        Expanded(
                          flex: 4,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Small visual human silhouette placeholder
                              CustomPaint(
                                size: const Size(60, 90),
                                painter: _MuscleSilhouettePainter(
                                  highlightColors: const [Colors.redAccent, Colors.orangeAccent],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                detail != null && detail.primaryMuscles.isNotEmpty
                                    ? detail.primaryMuscles.join(', ')
                                    : 'Quads, Glutes, Hamstrings',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF5A6A85),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 2: TARGET STATS (Weight, Reps, Rest)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D2D2D)),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTargetStatCell(
                            'Weight',
                            block.targetWeightKg > 0 ? block.targetWeightKg.toStringAsFixed(0) : '0',
                            'kg',
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFF2D2D2D)),
                        Expanded(
                          child: _buildTargetStatCell(
                            'Reps',
                            '${block.targetReps}',
                            'reps',
                          ),
                        ),
                        Container(width: 1, height: 40, color: const Color(0xFF2D2D2D)),
                        Expanded(
                          child: _buildTargetStatCell(
                            'Rest',
                            '${block.restSeconds > 0 ? block.restSeconds : 60}',
                            'sec',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 3: SESSION HISTORY CARD
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF2D2D2D)),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildHistoryContent(block),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 4: DETAILED INSTRUCTIONS (Visiable when scrolling down)
                  _buildDetailedInstructionsSection(detail),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // BOTTOM BAR - MARK SET COMPLETE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              border: Border(top: BorderSide(color: const Color(0xFF1E1E1E), width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _markCurrentSetComplete,
                icon: const Icon(Icons.check, color: Colors.white, size: 20),
                label: const Text(
                  'Mark Set Complete',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: AppColors.primaryGreen.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseIllustration(ExerciseCatalogDetail? detail) {
    // If we have a video thumbnail or image asset from C#, load it. Otherwise show a placeholder icon.
    final thumbnail = detail?.heroThumbnailUrl;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      return Image.network(
        thumbnail,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildIllustrationPlaceholder(),
      );
    }
    return _buildIllustrationPlaceholder();
  }

  Widget _buildIllustrationPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.fitness_center_outlined,
          color: Color(0xFF5A6A85),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildTargetStatCell(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryContent(SessionExecutionBlock block) {
    // Build set list that are logged completed in this active workout
    final completedIndexes = <int>[];
    for (int i = 0; i < _completedSets[_currentExerciseIndex].length; i++) {
      if (_completedSets[_currentExerciseIndex][i]) {
        completedIndexes.add(i);
      }
    }

    if (completedIndexes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có set nào hoàn thành.',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: completedIndexes.length,
      separatorBuilder: (_, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final realIndex = completedIndexes[idx];
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set ${realIndex + 1}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${block.targetWeightKg > 0 ? '${block.targetWeightKg.toStringAsFixed(0)} kg x ' : ''}${block.targetReps} reps',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF1F3D27), // Deep green background
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.primaryGreen, size: 14),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedInstructionsSection(ExerciseCatalogDetail? detail) {
    if (_loadingDetails) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (detail == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2D2D)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book, color: AppColors.primaryGreen, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Hướng dẫn thực hiện',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (detail.aiCoachingCues.isEmpty)
            const Text(
              'Thực hiện đúng form, giữ thẳng lưng, điều hòa nhịp thở.',
              style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            )
          else
            ...detail.aiCoachingCues.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final cue = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$idx. ',
                      style: const TextStyle(color: AppColors.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        cue,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Common Mistakes section
          if (detail.commonMistakes.isNotEmpty) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade400, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Lỗi thường gặp',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...detail.commonMistakes.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Expanded(
                      child: Text(
                        m,
                        style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Equipment section
          if (detail.equipmentRequired.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Thiết bị cần thiết',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detail.equipmentRequired.map((eq) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eq,
                    style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 2. COUNTDOWN REST VIEW
  Widget _buildRestView() {
    final nextBlock = _currentExerciseIndex < _session!.executionBlocks.length
        ? _session!.executionBlocks[_currentExerciseIndex]
        : null;

    final progressRatio = _restSecondsTotal > 0 ? (_restSecondsLeft / _restSecondsTotal) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'THỜI GIAN NGHỈ',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hít thở sâu & Thư giãn',
                style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),

              // Circular Countdown Visual
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progressRatio,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$_restSecondsLeft',
                            style: const TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'giây',
                            style: TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Next Exercise Preview Card
              if (nextBlock != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BÀI TẬP TIẾP THEO',
                        style: TextStyle(
                          color: AppColors.primaryGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        nextBlock.exerciseName,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextBlock.targetSets} sets x ${nextBlock.targetReps} reps • ${nextBlock.targetWeightKg}kg',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Timer Controllers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addRest30s,
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text('+30 giây', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _stopRest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Bỏ qua nghỉ', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // 3. WORKOUT FINISHED VIEW
  Widget _buildFinishedView() {
    final session = _session!;

    // Stats calculations
    int completedSetsCount = 0;
    double totalWeightLifted = 0;
    for (int i = 0; i < _completedSets.length; i++) {
      final block = session.executionBlocks[i];
      for (int s = 0; s < _completedSets[i].length; s++) {
        if (_completedSets[i][s]) {
          completedSetsCount++;
          totalWeightLifted += block.targetWeightKg * block.targetReps;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: AppColors.primaryGreen,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tuyệt vời!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bạn đã hoàn thành xuất sắc buổi tập của mình hôm nay.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const Spacer(),

              // Stats Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF2D2D2D)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildFinishedStatColumn(
                        'Thời gian',
                        _formatDuration(_workoutDurationSeconds),
                        Icons.timer_outlined,
                      ),
                    ),
                    Container(width: 1, height: 40, color: const Color(0xFF2D2D2D)),
                    Expanded(
                      child: _buildFinishedStatColumn(
                        'Set hoàn thành',
                        '$completedSetsCount',
                        Icons.check_circle_outline,
                      ),
                    ),
                    if (totalWeightLifted > 0) ...[
                      Container(width: 1, height: 40, color: const Color(0xFF2D2D2D)),
                      Expanded(
                        child: _buildFinishedStatColumn(
                          'Tổng tạ',
                          '${totalWeightLifted.toStringAsFixed(0)} kg',
                          Icons.fitness_center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // Done Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Hoàn tất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinishedStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryGreen),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }

  void _confirmExitWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Thoát buổi tập?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        content: const Text(
          'Quá trình tập luyện hiện tại sẽ không được lưu. Bạn có chắc chắn muốn thoát?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục tập', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelWorkoutExecution();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Thoát', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkoutExecution() async {
    try {
      final detail = await _repository.startWorkout(widget.sessionId, energyLevelBefore: 5);
      if (mounted) {
        setState(() {
          _executionId = detail.executionId;
        });
      }
    } catch (e) {
      debugPrint('Failed to start workout execution: $e');
    }
  }

  Future<void> _logSetComplete(SessionExecutionBlock block, int setNumber) async {
    final execId = _executionId;
    if (execId == null) {
      debugPrint('Cannot log set complete: _executionId is null');
      return;
    }
    try {
      await _repository.createExerciseSetLog(
        executionId: execId,
        exerciseId: block.exerciseId,
        setNumber: setNumber,
        targetReps: block.targetReps,
        actualReps: block.targetReps,
        weightKg: block.targetWeightKg,
        rir: 2,
        restTakenSeconds: block.restSeconds > 0 ? block.restSeconds : 60,
        formScore: 8,
        completed: true,
      );
    } catch (e) {
      debugPrint('Failed to log set complete to API: $e');
    }
  }

  Future<void> _submitFinishWorkout() async {
    final execId = _executionId;
    if (execId == null) {
      debugPrint('Cannot finish workout: _executionId is null');
      return;
    }
    try {
      await _repository.finishWorkout(
        execId,
        perceivedDifficulty: 3,
        energyLevelAfter: 4,
        sessionFeedback: 'Tập luyện hoàn tất trên thiết bị di động',
      );
    } catch (e) {
      debugPrint('Failed to finish workout: $e');
    }
  }

  Future<void> _cancelWorkoutExecution() async {
    final execId = _executionId;
    if (execId == null) return;
    try {
      await _repository.cancelWorkout(execId);
    } catch (e) {
      debugPrint('Failed to cancel workout execution: $e');
    }
  }
}

// Custom Painter representing target muscle highlights
class _MuscleSilhouettePainter extends CustomPainter {
  _MuscleSilhouettePainter({required this.highlightColors});

  final List<Color> highlightColors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1) // Default silhouette color
      ..style = PaintingStyle.fill;

    // Draw simple humanoid shapes representing human body model (front and back silhouettes)
    // Front Silhouette (Left side)
    final frontLeft = size.width * 0.25;
    // Draw head
    canvas.drawCircle(Offset(frontLeft, size.height * 0.15), size.height * 0.08, paint);
    // Draw torso
    final torsoPath = Path()
      ..moveTo(frontLeft - size.width * 0.08, size.height * 0.23)
      ..lineTo(frontLeft + size.width * 0.08, size.height * 0.23)
      ..lineTo(frontLeft + size.width * 0.06, size.height * 0.55)
      ..lineTo(frontLeft - size.width * 0.06, size.height * 0.55)
      ..close();
    canvas.drawPath(torsoPath, paint);
    // Draw arms
    canvas.drawRect(
      Rect.fromLTWH(frontLeft - size.width * 0.14, size.height * 0.23, size.width * 0.05, size.height * 0.32),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(frontLeft + size.width * 0.09, size.height * 0.23, size.width * 0.05, size.height * 0.32),
      paint,
    );

    // Draw legs with Highlight for Quads (front thigh muscles)
    final legPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.fill;
    final quadHighlightPaint = Paint()
      ..color = highlightColors[0]
      ..style = PaintingStyle.fill;

    // Left leg
    canvas.drawRect(
      Rect.fromLTWH(frontLeft - size.width * 0.06, size.height * 0.55, size.width * 0.05, size.height * 0.38),
      legPaint,
    );
    // Right leg
    canvas.drawRect(
      Rect.fromLTWH(frontLeft + size.width * 0.01, size.height * 0.55, size.width * 0.05, size.height * 0.38),
      legPaint,
    );

    // Quad highlight on thighs (front)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frontLeft - size.width * 0.055, size.height * 0.58, size.width * 0.04, size.height * 0.16),
        const Radius.circular(2),
      ),
      quadHighlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(frontLeft + size.width * 0.015, size.height * 0.58, size.width * 0.04, size.height * 0.16),
        const Radius.circular(2),
      ),
      quadHighlightPaint,
    );

    // Back Silhouette (Right side)
    final backLeft = size.width * 0.75;
    // Draw head
    canvas.drawCircle(Offset(backLeft, size.height * 0.15), size.height * 0.08, paint);
    // Draw torso
    final backTorsoPath = Path()
      ..moveTo(backLeft - size.width * 0.08, size.height * 0.23)
      ..lineTo(backLeft + size.width * 0.08, size.height * 0.23)
      ..lineTo(backLeft + size.width * 0.06, size.height * 0.55)
      ..lineTo(backLeft - size.width * 0.06, size.height * 0.55)
      ..close();
    canvas.drawPath(backTorsoPath, paint);
    // Draw arms
    canvas.drawRect(
      Rect.fromLTWH(backLeft - size.width * 0.14, size.height * 0.23, size.width * 0.05, size.height * 0.32),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(backLeft + size.width * 0.09, size.height * 0.23, size.width * 0.05, size.height * 0.32),
      paint,
    );

    // Draw legs
    canvas.drawRect(
      Rect.fromLTWH(backLeft - size.width * 0.06, size.height * 0.55, size.width * 0.05, size.height * 0.38),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(backLeft + size.width * 0.01, size.height * 0.55, size.width * 0.05, size.height * 0.38),
      legPaint,
    );

    // Draw Glutes and Hamstring Highlights (back)
    final gluteHamHighlightPaint = Paint()
      ..color = highlightColors.length > 1 ? highlightColors[1] : highlightColors[0]
      ..style = PaintingStyle.fill;

    // Glutes highlight (bottom torso / hips back)
    canvas.drawOval(
      Rect.fromLTWH(backLeft - size.width * 0.06, size.height * 0.50, size.width * 0.12, size.height * 0.08),
      gluteHamHighlightPaint,
    );

    // Hamstrings highlights (back thighs)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(backLeft - size.width * 0.055, size.height * 0.58, size.width * 0.04, size.height * 0.16),
        const Radius.circular(2),
      ),
      gluteHamHighlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(backLeft + size.width * 0.015, size.height * 0.58, size.width * 0.04, size.height * 0.16),
        const Radius.circular(2),
      ),
      gluteHamHighlightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
