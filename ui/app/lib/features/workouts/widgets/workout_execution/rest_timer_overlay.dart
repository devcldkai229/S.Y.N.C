import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';
import 'package:sync_app/features/workouts/widgets/workout_ui/workout_shared_widgets.dart';

class RestTimerOverlay extends StatefulWidget {
  const RestTimerOverlay({
    super.key,
    required this.secondsLeft,
    required this.totalSeconds,
    required this.upNextTitle,
    required this.upNextSubtitle,
    required this.onAdd30Seconds,
    required this.onSkipRest,
    this.nextExerciseName,
  });

  final int secondsLeft;
  final int totalSeconds;
  final String upNextTitle;
  final String upNextSubtitle;
  final VoidCallback onAdd30Seconds;
  final VoidCallback onSkipRest;
  final String? nextExerciseName;

  @override
  State<RestTimerOverlay> createState() => _RestTimerOverlayState();
}

class _RestTimerOverlayState extends State<RestTimerOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  int? _lastHapticSecond;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(RestTimerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.secondsLeft <= 3 && widget.secondsLeft > 0 && _lastHapticSecond != widget.secondsLeft) {
      _lastHapticSecond = widget.secondsLeft;
      HapticFeedback.lightImpact();
    }
    if (widget.secondsLeft == 0 && oldWidget.secondsLeft > 0) {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = widget.secondsLeft ~/ 60;
    final s = widget.secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _encouragement {
    if (widget.secondsLeft <= 5) return 'Sắp tới rồi — chuẩn bị nhé 💪';
    if (widget.secondsLeft <= 15) return 'Hít thở sâu, thư giãn cơ...';
    return 'Thời gian nghỉ — phục hồi năng lượng';
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.totalSeconds > 0 ? widget.secondsLeft / widget.totalSeconds : 0.0;
    final urgent = widget.secondsLeft <= 10;
    final ringColor = urgent ? const Color(0xFFF59E0B) : ExecutionTheme.syncLime;
    final sheetMaxHeight = MediaQuery.sizeOf(context).height * 0.62;

    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      child: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: sheetMaxHeight),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: ExecutionTheme.offWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: ExecutionTheme.border, borderRadius: BorderRadius.circular(4)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _encouragement,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: ExecutionTheme.slateMuted),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: ScaleTransition(
                        scale: urgent ? Tween<double>(begin: 1.0, end: 1.04).animate(_pulse) : const AlwaysStoppedAnimation(1.0),
                        child: SizedBox(
                          width: 210,
                          height: 210,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 210,
                                height: 210,
                                child: CircularProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  strokeWidth: 11,
                                  backgroundColor: ExecutionTheme.border,
                                  color: ringColor,
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Text(
                                _formattedTime,
                                style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: urgent ? const Color(0xFFB45309) : ExecutionTheme.slateDark,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: ExecutionTheme.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ExecutionTheme.border),
                      ),
                      child: Row(
                        children: [
                          ExerciseThumbnail(
                            exerciseName: widget.nextExerciseName ?? widget.upNextTitle,
                            size: 56,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TIẾP THEO',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1, color: ExecutionTheme.slateMuted),
                                ),
                                const SizedBox(height: 4),
                                Text(widget.upNextTitle, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: ExecutionTheme.slateDark)),
                                Text(widget.upNextSubtitle, style: const TextStyle(fontSize: 12, color: ExecutionTheme.slateMuted)),
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
                            onPressed: widget.onAdd30Seconds,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(ExecutionTheme.minTouchTarget),
                              side: const BorderSide(color: ExecutionTheme.slateDark, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('+30s', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: ExecutionTheme.slateDark)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: widget.onSkipRest,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(ExecutionTheme.minTouchTarget),
                              backgroundColor: ExecutionTheme.syncLime,
                              foregroundColor: ExecutionTheme.slateDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('BỎ QUA NGHỈ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.3)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
