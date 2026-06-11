import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

class OrderStatusStepper extends StatelessWidget {
  const OrderStatusStepper({super.key, required this.currentStatus});

  final String currentStatus;

  static const _steps = [
    ('Confirmed', 'Đã xác nhận'),
    ('Preparing', 'Đang chuẩn bị'),
    ('PickedUp', 'Shipper đã lấy'),
    ('Delivering', 'Đang giao'),
    ('Delivered', 'Đã giao'),
  ];

  int get _currentIndex {
    final idx = _steps.indexWhere((s) => s.$1 == currentStatus);
    if (idx >= 0) return idx;
    if (currentStatus == 'ReadyForPickup') return 1;
    if (currentStatus == 'Completed') return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(_steps.length, (i) {
        final active = i <= _currentIndex;
        return Row(
          children: [
            Icon(
              active ? Icons.check_circle : Icons.radio_button_unchecked,
              color: active ? MarketplaceTheme.primary : MarketplaceTheme.border,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              _steps[i].$2,
              style: TextStyle(
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? MarketplaceTheme.heading : MarketplaceTheme.textMuted,
              ),
            ),
          ],
        );
      }),
    );
  }
}
