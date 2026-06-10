import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:video_player/video_player.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

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
  int? _newStreak;

  // Exercise Detail Cache
  final Map<String, ExerciseCatalogDetail> _exerciseDetails = {};
  bool _loadingDetails = false;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  String? _videoError;

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
    _videoController?.dispose();
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
    _loadExerciseDetail(block.exerciseId).then((_) {
      if (mounted) {
        _initExerciseVideo(block.exerciseId);
      }
    });
  }

  Future<void> _initExerciseVideo(String exerciseId) async {
    final oldController = _videoController;
    _videoController = null;
    _videoReady = false;
    _videoError = null;
    if (oldController != null) {
      oldController.dispose();
    }
    if (mounted) {
      setState(() {});
    }

    final detail = _exerciseDetails[exerciseId];
    if (detail == null) return;

    final videos = detail.videoAssets;
    if (videos.isEmpty) return;

    final url = videos.first.resourceUrl;
    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _videoReady = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _videoError = e.toString();
      });
      debugPrint('Failed to initialize exercise video: $e');
    }
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
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGreen)),
      );
    }

    if (_error != null || _session == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background, // Light white-green premium background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary, size: 24),
          onPressed: () => _confirmExitWorkout(),
        ),
        title: Column(
          children: [
            Text(
              block.exerciseName,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              'Set ${_currentSetIndex + 1} of ${block.targetSets}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Text(
                _formatDuration(_workoutDurationSeconds),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: AppColors.textPrimary, size: 20),
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
                  // CARD 1: PREMIUM VIDEO PLAYER CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: _buildActiveExerciseVideo(detail),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // CARD 2: TARGET STATS (Weight, Reps, Rest)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
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
                        Container(width: 1, height: 40, color: AppColors.border),
                        Expanded(
                          child: _buildTargetStatCell(
                            'Reps',
                            '${block.targetReps}',
                            'reps',
                          ),
                        ),
                        Container(width: 1, height: 40, color: AppColors.border),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'History',
                          style: TextStyle(
                            color: AppColors.textPrimary,
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
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
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

  Widget _buildActiveExerciseVideo(ExerciseCatalogDetail? detail) {
    if (_loadingDetails) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryGreen),
      );
    }

    final controller = _videoController;
    final videos = detail?.videoAssets;
    final heroThumb = detail?.heroThumbnailUrl;

    if (videos != null && videos.isNotEmpty && controller != null) {
      return _VideoHero(
        controller: controller,
        ready: _videoReady,
        error: _videoError,
        thumbnailUrl: heroThumb,
        onFullscreen: () {
          final rawUrl = videos.first.resourceUrl;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => SocialVideoPlayerScreen(videoUrl: rawUrl),
            ),
          );
        },
      );
    }

    if (heroThumb != null && heroThumb.isNotEmpty) {
      return _ImageHero(imageUrl: heroThumb);
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
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            color: AppColors.textSecondary,
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
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
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
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${block.targetWeightKg > 0 ? '${block.targetWeightKg.toStringAsFixed(0)} kg x ' : ''}${block.targetReps} reps',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.lightGreen,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
                style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (detail.aiCoachingCues.isEmpty)
            const Text(
              'Thực hiện đúng form, giữ thẳng lưng, điều hòa nhịp thở.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
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
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
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
                    const Text('• ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Expanded(
                      child: Text(
                        m,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
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
              style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: detail.equipmentRequired.map((eq) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    eq,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'THỜI GIAN NGHỈ',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hít thở sâu & Thư giãn',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
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
                          backgroundColor: Colors.black.withValues(alpha: 0.05),
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
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Text(
                            'giây',
                            style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.bold),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
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
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${nextBlock.targetSets} sets x ${nextBlock.targetReps} reps • ${nextBlock.targetWeightKg}kg',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                      icon: const Icon(Icons.add, color: AppColors.primaryGreen, size: 18),
                      label: const Text('+30 giây', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryGreen),
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
      backgroundColor: AppColors.background,
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
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              if (_newStreak != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 4),
                    Text(
                      'Streak: $_newStreak ngày',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              const Text(
                'Bạn đã hoàn thành xuất sắc buổi tập của mình hôm nay.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const Spacer(),

              // Stats Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
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
                    Container(width: 1, height: 40, color: AppColors.border),
                    Expanded(
                      child: _buildFinishedStatColumn(
                        'Set hoàn thành',
                        '$completedSetsCount',
                        Icons.check_circle_outline,
                      ),
                    ),
                    if (totalWeightLifted > 0) ...[
                      Container(width: 1, height: 40, color: AppColors.border),
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
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ],
    );
  }

  void _confirmExitWorkout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Thoát buổi tập?', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        content: const Text(
          'Quá trình tập luyện hiện tại sẽ không được lưu. Bạn có chắc chắn muốn thoát?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tiếp tục tập', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
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
      
      // Auto log activity to increment streak on workout completion
      try {
        final activityResult = await getIt<ProfileApiService>().logActivity();
        if (mounted) {
          setState(() {
            _newStreak = activityResult.currentStreak;
          });
        }
        debugPrint('Auto logged activity! Current streak: ${activityResult.currentStreak}');
      } catch (activityError) {
        debugPrint('Failed to auto log activity after finishing workout: $activityError');
      }
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

class _VideoHero extends StatefulWidget {
  const _VideoHero({
    required this.controller,
    required this.ready,
    required this.error,
    required this.onFullscreen,
    this.thumbnailUrl,
  });

  final VideoPlayerController controller;
  final bool ready;
  final String? error;
  final String? thumbnailUrl;
  final VoidCallback onFullscreen;

  @override
  State<_VideoHero> createState() => _VideoHeroState();
}

class _VideoHeroState extends State<_VideoHero> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: widget.ready && controller.value.aspectRatio > 0
              ? controller.value.aspectRatio
              : 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: widget.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Video unavailable.\nUse fullscreen to retry.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  )
                : !widget.ready
                    ? widget.thumbnailUrl != null
                        ? CachedNetworkImage(imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                    : VideoPlayer(controller),
          ),
        ),
        if (widget.ready)
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: [
                _OverlayButton(
                  icon: controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  onTap: () {
                    controller.value.isPlaying ? controller.pause() : controller.play();
                  },
                ),
                const SizedBox(width: 8),
                _OverlayButton(icon: Icons.fullscreen, onTap: widget.onFullscreen),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageHero extends StatelessWidget {
  const _ImageHero({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => ColoredBox(
          color: AppColors.lightGreen.withValues(alpha: 0.3),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => ColoredBox(
          color: AppColors.backgroundAlt,
          child: const Icon(Icons.broken_image_outlined, size: 48),
        ),
      ),
    );
  }
}

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

