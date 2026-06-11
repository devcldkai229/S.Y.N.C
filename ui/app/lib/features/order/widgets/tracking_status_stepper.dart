import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';

class TrackingStatusStepper extends StatelessWidget {
  const TrackingStatusStepper({
    super.key,
    required this.currentStatus,
    this.timestamps,
  });

  final String currentStatus;
  final List<DateTime?>? timestamps;

  static const _steps = [
    ('Confirmed', 'Đã xác nhận'),
    ('Preparing', 'Đang chuẩn bị'),
    ('PickedUp', 'Đã lấy hàng'),
    ('Delivering', 'Đang giao'),
    ('Delivered', 'Đã giao'),
  ];

  int get _currentIndex {
    final idx = _steps.indexWhere((s) => s.$1 == currentStatus);
    if (idx >= 0) return idx;
    if (currentStatus == 'Completed') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_steps.length, (i) {
        final done = i < _currentIndex;
        final active = i == _currentIndex;
        final isLast = i == _steps.length - 1;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  _StepDot(done: done, active: active),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 14),
                        color: done ? OrderTheme.accent : OrderTheme.line,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _steps[i].$2,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  color: active
                      ? OrderTheme.accent
                      : done
                          ? OrderTheme.textPrimary
                          : OrderTheme.textMuted,
                  height: 1.2,
                ),
              ),
              if (timestamps != null && i < timestamps!.length && timestamps![i] != null) ...[
                const SizedBox(height: 2),
                Text(
                  timeFmt.format(timestamps![i]!.toLocal()),
                  style: const TextStyle(fontSize: 9, color: OrderTheme.textMuted),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 18,
        height: 18,
        decoration: const BoxDecoration(color: OrderTheme.accent, shape: BoxShape.circle),
        child: const Icon(Icons.check, size: 12, color: Colors.white),
      );
    }
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? OrderTheme.accent : Colors.white,
        border: Border.all(
          color: active ? OrderTheme.accent : OrderTheme.line,
          width: 2,
        ),
      ),
    );
  }
}
