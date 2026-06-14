import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/currency_formatter.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/widgets/status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final OrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = order.items.map((i) => i.nameSnapshot).take(2).join(', ');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: MarketplaceTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.w800))),
                StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(summary, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            Text(
              '${CurrencyFormatter.formatVnd(order.totalAmount)} · ${order.placedAt.toLocal()}',
              style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
