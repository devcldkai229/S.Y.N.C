import 'package:flutter/material.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';

class EtaBanner extends StatelessWidget {
  const EtaBanner({
    super.key,
    required this.etaMinutes,
    this.statusMessage,
    this.isDelivered = false,
  });

  final int? etaMinutes;
  final String? statusMessage;
  final bool isDelivered;

  @override
  Widget build(BuildContext context) {
    final headline = isDelivered
        ? 'Đã giao thành công'
        : etaMinutes != null && etaMinutes! > 0
            ? 'Dự kiến giao sau ~$etaMinutes phút'
            : 'Đang cập nhật thời gian giao';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          headline,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: OrderTheme.textPrimary,
            height: 1.2,
          ),
        ),
        if (statusMessage != null && statusMessage!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            statusMessage!,
            style: const TextStyle(fontSize: 14, color: OrderTheme.textMuted),
          ),
        ],
      ],
    );
  }
}
