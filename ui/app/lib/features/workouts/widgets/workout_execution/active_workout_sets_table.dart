import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/workouts/widgets/workout_execution/execution_theme.dart';

class SetRowData {
  SetRowData({
    required this.setNumber,
    required this.previousLabel,
    required this.weightController,
    required this.repsController,
    required this.completed,
    this.isActive = false,
    this.isFuture = false,
    this.onToggleDone,
  });

  final int setNumber;
  final String previousLabel;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final bool completed;
  final bool isActive;
  final bool isFuture;
  final VoidCallback? onToggleDone;
}

class ActiveWorkoutSetsTable extends StatelessWidget {
  const ActiveWorkoutSetsTable({super.key, required this.rows});

  final List<SetRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _TableHeader(),
        const SizedBox(height: 8),
        ...rows.map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SetRow(data: row),
            )),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      color: ExecutionTheme.slateMuted,
      letterSpacing: 0.8,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('SET', style: style)),
          Expanded(flex: 3, child: Text('PREVIOUS', style: style)),
          Expanded(flex: 2, child: Text('KG', style: style, textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Text('REPS', style: style, textAlign: TextAlign.center)),
          SizedBox(width: 64, child: Text('DONE', style: style, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

class _SetRow extends StatelessWidget {
  const _SetRow({required this.data});

  final SetRowData data;

  @override
  Widget build(BuildContext context) {
    final done = data.completed;
    final active = data.isActive && !done;
    final future = data.isFuture && !done;

    final bgColor = active ? ExecutionTheme.cardWhite : (done ? ExecutionTheme.rowDoneFill : ExecutionTheme.inputFill);
    final opacity = future ? 0.45 : (done ? 0.65 : 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? ExecutionTheme.syncLime.withValues(alpha: 0.5) : ExecutionTheme.border,
          width: active ? 1.5 : 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: ExecutionTheme.slateDark.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: CircleAvatar(
                  radius: 15,
                  backgroundColor: done
                      ? ExecutionTheme.syncLime
                      : (active ? ExecutionTheme.slateDark : ExecutionTheme.border),
                  child: Text(
                    '${data.setNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: done || active ? ExecutionTheme.slateDark : ExecutionTheme.slateMuted,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  data.previousLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: ExecutionTheme.slateMuted,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: _SetInput(
                  controller: data.weightController,
                  enabled: active,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: _SetInput(
                  controller: data.repsController,
                  enabled: active,
                  isReps: true,
                ),
              ),
              SizedBox(
                width: 64,
                height: ExecutionTheme.minTouchTarget,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: done || data.onToggleDone == null
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            data.onToggleDone!();
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: done ? ExecutionTheme.syncLime : Colors.transparent,
                          border: Border.all(
                            color: done ? ExecutionTheme.syncLime : ExecutionTheme.border,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          done ? Icons.check_rounded : Icons.check_rounded,
                          color: done ? ExecutionTheme.slateDark : ExecutionTheme.border,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetInput extends StatelessWidget {
  const _SetInput({
    required this.controller,
    required this.enabled,
    this.isReps = false,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool isReps;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        if (isReps) FilteringTextInputFormatter.digitsOnly else FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: enabled ? ExecutionTheme.slateDark : ExecutionTheme.slateMuted,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: enabled ? ExecutionTheme.inputFill : ExecutionTheme.offWhite,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      ),
    );
  }
}
