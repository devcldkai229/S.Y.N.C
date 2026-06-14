import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';

class OrderSummaryCompact extends StatelessWidget {
  const OrderSummaryCompact({super.key, required this.order});

  final OrderSummary order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: OrderTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tóm tắt đơn', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          ...order.items.map(
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${i.quantity}x ${i.nameSnapshot}',
                style: const TextStyle(fontSize: 14, color: OrderTheme.textPrimary),
              ),
            ),
          ),
          const Divider(height: 20),
          Text(
            MarketplaceFormatters.formatVnd(order.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: OrderTheme.accent),
          ),
          if (order.deliveryAddress != null) ...[
            const SizedBox(height: 8),
            Text(
              'Giao: ${order.deliveryAddress}',
              style: const TextStyle(fontSize: 13, color: OrderTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}
