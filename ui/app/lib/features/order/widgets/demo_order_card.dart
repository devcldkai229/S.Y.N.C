import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/order/mock/order_demo_data.dart';
import 'package:sync_app/features/order/utils/order_display_status.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';

class DemoOrderCard extends StatelessWidget {
  const DemoOrderCard({super.key, required this.item, required this.onTap});

  final OrderListItemVm item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final order = item.order;
    final itemSummary = order.items.map((i) => i.nameSnapshot).join(' · ');
    final timeFmt = DateFormat('HH:mm');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: OrderTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.partnerName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
                _NeutralStatusChip(
                  label: OrderDisplayStatus.label(order.displayStatus),
                  highlighted: order.isActive,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              itemSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: OrderTheme.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  MarketplaceFormatters.formatVnd(order.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  item.etaMinutes != null && order.isActive
                      ? 'ETA ~${item.etaMinutes} phút · ${timeFmt.format(order.placedAt.toLocal())}'
                      : timeFmt.format(order.placedAt.toLocal()),
                  style: const TextStyle(fontSize: 12, color: OrderTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NeutralStatusChip extends StatelessWidget {
  const _NeutralStatusChip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? OrderTheme.accent.withValues(alpha: 0.12) : OrderTheme.line,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: highlighted ? OrderTheme.accent : OrderTheme.textMuted,
        ),
      ),
    );
  }
}
