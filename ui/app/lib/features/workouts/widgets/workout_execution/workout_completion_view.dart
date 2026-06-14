import 'package:flutter/material.dart';
import 'package:sync_app/features/workouts/theme/workout_theme.dart';

class WorkoutCompletionView extends StatefulWidget {
  const WorkoutCompletionView({
    super.key,
    required this.durationSeconds,
    required this.completedSets,
    required this.totalVolumeKg,
    this.streakDays,
    required this.onDone,
  });

  final int durationSeconds;
  final int completedSets;
  final double totalVolumeKg;
  final int? streakDays;
  final VoidCallback onDone;

  @override
  State<WorkoutCompletionView> createState() => _WorkoutCompletionViewState();
}

class _WorkoutCompletionViewState extends State<WorkoutCompletionView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WorkoutTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.08).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut)),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: WorkoutTheme.lime.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    boxShadow: WorkoutTheme.cardShadow(opacity: 0.12),
                  ),
                  child: const Icon(Icons.emoji_events_rounded, size: 52, color: WorkoutTheme.forest),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Buổi tập hoàn tất!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text(
                'Bạn đã làm tốt lắm — hãy nghỉ ngơi và bổ sung dinh dưỡng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: WorkoutTheme.textMuted, fontSize: 14, height: 1.4),
              ),
              if (widget.streakDays != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department_rounded, color: Colors.orange, size: 22),
                    const SizedBox(width: 6),
                    Text('Streak ${widget.streakDays} ngày', style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.orange, fontSize: 15)),
                  ],
                ),
              ],
              const Spacer(),
              _statsCard(),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: WorkoutTheme.minTouch,
                child: FilledButton(
                  onPressed: widget.onDone,
                  style: FilledButton.styleFrom(
                    backgroundColor: WorkoutTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Hoàn thành', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: WorkoutTheme.card,
        borderRadius: WorkoutTheme.radiusLg,
        border: Border.all(color: WorkoutTheme.border),
        boxShadow: WorkoutTheme.cardShadow(),
      ),
      child: Row(
        children: [
          Expanded(child: _stat('Thời gian', _formatDuration(widget.durationSeconds), Icons.timer_outlined)),
          _divider(),
          Expanded(child: _stat('Sets', '${widget.completedSets}', Icons.check_circle_outline)),
          if (widget.totalVolumeKg > 0) ...[
            _divider(),
            Expanded(child: _stat('Volume', '${widget.totalVolumeKg.toStringAsFixed(0)} kg', Icons.fitness_center)),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 44, color: WorkoutTheme.border, margin: const EdgeInsets.symmetric(horizontal: 8));

  Widget _stat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: WorkoutTheme.primary),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: WorkoutTheme.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: WorkoutTheme.textPrimary)),
      ],
    );
  }
}
