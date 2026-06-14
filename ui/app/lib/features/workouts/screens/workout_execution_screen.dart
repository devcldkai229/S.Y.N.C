import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/api_error_mapper.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/workout_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/screens/social_video_player_screen.dart';
import 'package:sync_app/features/workouts/models/workout_models.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/focus_exercise_page.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/rest_timer_bottom_sheet.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/session_progress_bar.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/workout_completion_view.dart';
import 'package:video_player/video_player.dart';

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
  late final PageController _pageController;

  RoadmapSession? _session;
  String? _executionId;
  bool _loading = true;
  String? _error;

  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  List<List<bool>> _completedSets = [];
  final List<List<TextEditingController>> _weightControllers = [];
  final List<List<TextEditingController>> _repsControllers = [];

  bool _isResting = false;
  int _workoutDurationSeconds = 0;
  Timer? _workoutTimer;

  bool _isFinished = false;
  int? _newStreak;

  final Map<String, ExerciseCatalogDetail> _exerciseDetails = {};
  bool _loadingDetails = false;
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    _videoController?.dispose();
    _pageController.dispose();
    _disposeSetControllers();
    super.dispose();
  }

  void _disposeSetControllers() {
    for (final row in _weightControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    for (final row in _repsControllers) {
      for (final c in row) {
        c.dispose();
      }
    }
    _weightControllers.clear();
    _repsControllers.clear();
  }

  void _initAllSetControllers() {
    _disposeSetControllers();
    final session = _session;
    if (session == null) return;

    for (final block in session.executionBlocks) {
      final weights = <TextEditingController>[];
      final reps = <TextEditingController>[];
      for (var i = 0; i < block.targetSets; i++) {
        final w = block.targetWeightKg;
        weights.add(
          TextEditingController(
            text: w > 0 ? w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1) : '0',
          ),
        );
        reps.add(TextEditingController(text: '${block.targetReps}'));
      }
      _weightControllers.add(weights);
      _repsControllers.add(reps);
    }
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

    _completedSets = List.generate(
      session.executionBlocks.length,
      (i) => List.filled(session.executionBlocks[i].targetSets, false),
    );

    _workoutDurationSeconds = 0;
    _workoutTimer?.cancel();
    _workoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_isFinished) {
        setState(() => _workoutDurationSeconds++);
      }
    });

    _initAllSetControllers();

    setState(() {
      _currentExerciseIndex = 0;
      _currentSetIndex = 0;
      _isResting = false;
      _isFinished = false;
      _loading = false;
    });

    _preloadExerciseDetails();
    _onExerciseChanged();
    _startWorkoutExecution();
  }

  Future<void> _preloadExerciseDetails() async {
    final session = _session;
    if (session == null) return;
    for (final block in session.executionBlocks) {
      await _loadExerciseDetail(block.exerciseId);
    }
  }

  void _onExerciseChanged() {
    final session = _session;
    if (session == null) return;
    final block = session.executionBlocks[_currentExerciseIndex];
    _loadExerciseDetail(block.exerciseId).then((_) {
      if (mounted) _initExerciseVideo(block.exerciseId);
    });
  }

  Future<void> _initExerciseVideo(String exerciseId) async {
    final oldController = _videoController;
    _videoController = null;
    _videoReady = false;
    _videoError = null;
    oldController?.dispose();
    if (mounted) setState(() {});

    final detail = _exerciseDetails[exerciseId];
    final videos = detail?.videoAssets;
    if (videos == null || videos.isEmpty) return;

    final controller = VideoPlayerController.networkUrl(Uri.parse(videos.first.resourceUrl));
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;
      setState(() => _videoReady = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _videoError = e.toString());
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
      } else if (mounted) {
        setState(() => _loadingDetails = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingDetails = false);
    }
  }

  double _overallProgress() {
    var total = 0;
    var done = 0;
    for (final sets in _completedSets) {
      total += sets.length;
      done += sets.where((c) => c).length;
    }
    return total == 0 ? 0 : done / total;
  }

  String _previousLabel(SessionExecutionBlock block, int setIndex) {
    if (setIndex == 0) return '—';
    final w = block.targetWeightKg;
    final weightPart = w > 0
        ? '${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)}kg'
        : '0kg';
    return '${block.targetReps}x$weightPart';
  }

  String _exerciseSubtitle(SessionExecutionBlock block, String sessionType) {
    final focus = sessionType.isNotEmpty ? sessionType : 'Strength';
    final unit = block.exerciseName.toLowerCase().contains('plank') ? 's' : 'reps';
    return '$focus • ${block.targetSets} Sets · ${block.targetReps}$unit';
  }

  ({
    String label,
    String detail,
    String exerciseName,
    String? thumbnailUrl,
  }) _upNextContext(int exerciseIndex, int completedSetIndex) {
    final session = _session!;
    final block = session.executionBlocks[exerciseIndex];

    if (completedSetIndex < block.targetSets - 1) {
      final nextSet = completedSetIndex + 2;
      final reps = _repsControllers[exerciseIndex][completedSetIndex + 1].text;
      final kg = _weightControllers[exerciseIndex][completedSetIndex + 1].text;
      return (
        label: 'Tiếp theo: Set $nextSet',
        detail: '$reps reps @ ${kg}kg',
        exerciseName: block.exerciseName,
        thumbnailUrl: _exerciseDetails[block.exerciseId]?.heroThumbnailUrl,
      );
    }

    final next = session.executionBlocks[exerciseIndex + 1];
    final detail = _formatExerciseSetsSummary(next);
    return (
      label: 'Bài tiếp theo: ${next.exerciseName}',
      detail: detail,
      exerciseName: next.exerciseName,
      thumbnailUrl: _exerciseDetails[next.exerciseId]?.heroThumbnailUrl,
    );
  }

  String _formatExerciseSetsSummary(SessionExecutionBlock block) {
    if (block.exerciseName.toLowerCase().contains('plank')) {
      return '${block.targetSets} sets x ${block.targetReps}s';
    }
    final w = block.targetWeightKg;
    final weight = w > 0 ? ' @ ${w.toStringAsFixed(w.truncateToDouble() == w ? 0 : 1)}kg' : '';
    return '${block.targetSets} sets x ${block.targetReps} reps$weight';
  }

  Future<void> _markSetComplete(int setIndex) async {
    if (_isResting || _isFinished) return;
    final ei = _currentExerciseIndex;
    if (setIndex != _currentSetIndex) return;
    if (_completedSets[ei][setIndex]) return;

    final session = _session!;
    final block = session.executionBlocks[ei];
    final weight = double.tryParse(_weightControllers[ei][setIndex].text) ?? block.targetWeightKg;
    final reps = int.tryParse(_repsControllers[ei][setIndex].text) ?? block.targetReps;

    setState(() => _completedSets[ei][setIndex] = true);
    HapticFeedback.mediumImpact();

    await _logSetComplete(
      block,
      setIndex + 1,
      actualReps: reps,
      weightKg: weight,
    );

    final isLastSet = setIndex == block.targetSets - 1;
    final isLastExercise = ei == session.executionBlocks.length - 1;

    if (isLastSet && isLastExercise) {
      _finishWorkout();
      return;
    }

    final restSeconds = block.restSeconds > 0 ? block.restSeconds : 60;
    final upNext = _upNextContext(ei, setIndex);

    if (!mounted) return;
    setState(() => _isResting = true);
    await RestTimerBottomSheet.show(
      context,
      seconds: restSeconds,
      upNextLabel: upNext.label,
      upNextDetail: upNext.detail,
      nextExerciseName: upNext.exerciseName,
      nextExerciseThumbnailUrl: upNext.thumbnailUrl,
    );
    if (!mounted) return;
    setState(() => _isResting = false);

    await _advanceAfterRest(ei, setIndex);
  }

  Future<void> _advanceAfterRest(int exerciseIndex, int completedSetIndex) async {
    final session = _session!;
    final block = session.executionBlocks[exerciseIndex];

    if (completedSetIndex < block.targetSets - 1) {
      setState(() => _currentSetIndex = completedSetIndex + 1);
      return;
    }

    if (exerciseIndex >= session.executionBlocks.length - 1) return;

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;

    setState(() {
      _currentExerciseIndex = exerciseIndex + 1;
      _currentSetIndex = 0;
    });
    _onExerciseChanged();
  }

  void _finishWorkout() {
    _workoutTimer?.cancel();
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

  double _computeTotalVolume() {
    final session = _session;
    if (session == null) return 0;
    var volume = 0.0;
    for (var ei = 0; ei < _completedSets.length; ei++) {
      final block = session.executionBlocks[ei];
      for (var si = 0; si < _completedSets[ei].length; si++) {
        if (!_completedSets[ei][si]) continue;
        final w = double.tryParse(_weightControllers[ei][si].text) ?? block.targetWeightKg;
        final r = int.tryParse(_repsControllers[ei][si].text) ?? block.targetReps;
        volume += w * r;
      }
    }
    return volume;
  }

  int _completedSetsCount() {
    var count = 0;
    for (final sets in _completedSets) {
      count += sets.where((c) => c).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: ExecutionTheme.offWhite,
        body: Center(child: CircularProgressIndicator(color: ExecutionTheme.syncLime)),
      );
    }

    if (_error != null || _session == null) {
      return Scaffold(
        backgroundColor: ExecutionTheme.offWhite,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Không thể tải buổi tập', style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSession,
                style: ElevatedButton.styleFrom(backgroundColor: ExecutionTheme.syncLime),
                child: const Text('Thử lại', style: TextStyle(color: ExecutionTheme.slateDark)),
              ),
            ],
          ),
        ),
      );
    }

    if (_isFinished) {
      return WorkoutCompletionView(
        durationSeconds: _workoutDurationSeconds,
        completedSets: _completedSetsCount(),
        totalVolumeKg: _computeTotalVolume(),
        streakDays: _newStreak,
        onDone: () => context.pop(true),
      );
    }

    return _buildFocusModeView();
  }

  Widget _buildFocusModeView() {
    final session = _session!;
    final block = session.executionBlocks[_currentExerciseIndex];

    return Scaffold(
      backgroundColor: ExecutionTheme.offWhite,
      appBar: AppBar(
        backgroundColor: ExecutionTheme.offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: ExecutionTheme.slateDark, size: 26),
          onPressed: _confirmExitWorkout,
        ),
        title: Text(
          _formatDuration(_workoutDurationSeconds),
          style: const TextStyle(
            color: ExecutionTheme.slateDark,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
        actions: const [
          SizedBox(width: 48),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SessionProgressBar(
            sessionTitle: session.sessionTitle,
            exerciseIndex: _currentExerciseIndex + 1,
            exerciseTotal: session.executionBlocks.length,
            setIndex: _currentSetIndex + 1,
            setTotal: block.targetSets,
            overallProgress: _overallProgress(),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: session.executionBlocks.length,
              itemBuilder: (context, index) {
                final exerciseBlock = session.executionBlocks[index];
                final detail = _exerciseDetails[exerciseBlock.exerciseId];
                final videos = detail?.videoAssets;
                final isCurrent = index == _currentExerciseIndex;

                return FocusExercisePage(
                  block: exerciseBlock,
                  exerciseIndex: index,
                  exerciseTotal: session.executionBlocks.length,
                  activeSetIndex: isCurrent ? _currentSetIndex : 0,
                  completedSets: _completedSets[index],
                  weightControllers: _weightControllers[index],
                  repsControllers: _repsControllers[index],
                  previousLabel: (setIndex) => _previousLabel(exerciseBlock, setIndex),
                  onSetDone: isCurrent ? _markSetComplete : (_) {},
                  detail: detail,
                  loadingDetail: _loadingDetails,
                  videoController: isCurrent ? _videoController : null,
                  videoReady: isCurrent && _videoReady,
                  videoError: isCurrent ? _videoError : null,
                  onFullscreen: isCurrent && videos != null && videos.isNotEmpty
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SocialVideoPlayerScreen(videoUrl: videos.first.resourceUrl),
                            ),
                          );
                        }
                      : null,
                  isCurrentPage: isCurrent,
                  subtitle: _exerciseSubtitle(exerciseBlock, session.sessionType),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmExitWorkout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'End Workout early?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        content: const Text(
          'Tiến trình hiện tại sẽ không được lưu. Bạn có chắc muốn kết thúc sớm?',
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
            child: const Text('Kết thúc', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _startWorkoutExecution() async {
    try {
      final detail = await _repository.startWorkout(widget.sessionId, energyLevelBefore: 5);
      if (mounted) setState(() => _executionId = detail.executionId);
    } catch (e) {
      debugPrint('Failed to start workout execution: $e');
    }
  }

  Future<void> _logSetComplete(
    SessionExecutionBlock block,
    int setNumber, {
    required int actualReps,
    required double weightKg,
  }) async {
    final execId = _executionId;
    if (execId == null) return;
    try {
      await _repository.createExerciseSetLog(
        executionId: execId,
        exerciseId: block.exerciseId,
        setNumber: setNumber,
        targetReps: block.targetReps,
        actualReps: actualReps,
        weightKg: weightKg,
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
    if (execId == null) return;
    try {
      await _repository.finishWorkout(
        execId,
        perceivedDifficulty: 3,
        energyLevelAfter: 4,
        sessionFeedback: 'Tập luyện hoàn tất trên thiết bị di động',
      );

      try {
        final activityResult = await getIt<ProfileApiService>().logActivity();
        if (mounted) setState(() => _newStreak = activityResult.currentStreak);
      } catch (activityError) {
        debugPrint('Failed to auto log activity: $activityError');
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
