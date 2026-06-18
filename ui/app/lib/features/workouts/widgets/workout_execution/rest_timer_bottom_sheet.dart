import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';

/// Modal rest timer with contextual "up next" preview.
class RestTimerBottomSheet extends StatefulWidget {
  const RestTimerBottomSheet({
    super.key,
    required this.initialSeconds,
    required this.upNextLabel,
    required this.upNextDetail,
    required this.nextExerciseName,
    this.nextExerciseThumbnailUrl,
  });

  final int initialSeconds;
  final String upNextLabel;
  final String upNextDetail;
  final String nextExerciseName;
  final String? nextExerciseThumbnailUrl;

  static Future<void> show(
    BuildContext context, {
    required int seconds,
    required String upNextLabel,
    required String upNextDetail,
    required String nextExerciseName,
    String? nextExerciseThumbnailUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RestTimerBottomSheet(
        initialSeconds: seconds,
        upNextLabel: upNextLabel,
        upNextDetail: upNextDetail,
        nextExerciseName: nextExerciseName,
        nextExerciseThumbnailUrl: nextExerciseThumbnailUrl,
      ),
    );
  }

  @override
  State<RestTimerBottomSheet> createState() => _RestTimerBottomSheetState();
}

class _RestTimerBottomSheetState extends State<RestTimerBottomSheet> with SingleTickerProviderStateMixin {
  late int _secondsLeft;
  late int _totalSeconds;
  Timer? _timer;
  late AnimationController _pulse;
  int? _lastHapticSecond;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.initialSeconds;
    _totalSeconds = widget.initialSeconds;
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
        Navigator.of(context).pop();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _add30() {
    HapticFeedback.selectionClick();
    setState(() {
      _secondsLeft += 30;
      _totalSeconds += 30;
    });
  }

  void _skip() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void didUpdateWidget(RestTimerBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_secondsLeft <= 3 && _secondsLeft > 0 && _lastHapticSecond != _secondsLeft) {
      _lastHapticSecond = _secondsLeft;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalSeconds > 0 ? _secondsLeft / _totalSeconds : 0.0;
    final urgent = _secondsLeft <= 10;
    final ringColor = urgent ? const Color(0xFFF59E0B) : ExecutionTheme.syncLime;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: ExecutionTheme.offWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: ExecutionTheme.border, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 20),
            const Text(
              'THỜI GIAN NGHỈ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
                color: ExecutionTheme.slateMuted,
              ),
            ),
            const SizedBox(height: 24),
            ScaleTransition(
              scale: urgent ? Tween<double>(begin: 1.0, end: 1.05).animate(_pulse) : const AlwaysStoppedAnimation(1.0),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: CircularProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        strokeWidth: 12,
                        backgroundColor: ExecutionTheme.border,
                        color: ringColor,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        color: urgent ? const Color(0xFFB45309) : ExecutionTheme.slateDark,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: ExecutionTheme.cardWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ExecutionTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: ExecutionTheme.slateDark.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ExerciseThumbnail(
                    exerciseName: widget.nextExerciseName,
                    networkUrl: widget.nextExerciseThumbnailUrl,
                    size: 56,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UP NEXT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: ExecutionTheme.slateMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.upNextLabel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: ExecutionTheme.slateDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.upNextDetail,
                          style: const TextStyle(fontSize: 12, color: ExecutionTheme.slateMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _add30,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(ExecutionTheme.minTouchTarget),
                      side: const BorderSide(color: ExecutionTheme.slateDark, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      '+30s',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: ExecutionTheme.slateDark),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _skip,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(ExecutionTheme.minTouchTarget),
                      backgroundColor: ExecutionTheme.syncLime,
                      foregroundColor: ExecutionTheme.slateDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'BỎ QUA NGHỈ',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
