import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  Color get _color => switch (status) {
        'Completed' || 'Delivered' => Colors.green,
        'Cancelled' || 'Refunded' => Colors.grey,
        'Delivering' || 'PickedUp' => Colors.blue,
        _ => const Color(0xFF2E6B4F),
      };

  String get _label => switch (status) {
        'Confirmed' => 'Đã xác nhận',
        'Preparing' => 'Đang chuẩn bị',
        'ReadyForPickup' => 'Chờ shipper',
        'PickedUp' => 'Đã lấy hàng',
        'Delivering' => 'Đang giao',
        'Delivered' => 'Đã giao',
        'Completed' => 'Hoàn tất',
        'Cancelled' => 'Đã hủy',
        _ => status,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(_label, style: TextStyle(fontSize: 11, color: _color, fontWeight: FontWeight.w600)),
    );
  }
}
