import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/currency_formatter.dart';

class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({
    super.key,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row('Tạm tính', subtotal),
        _row('Phí giao', deliveryFee),
        if (discount > 0) _row('Giảm giá', -discount),
        const Divider(),
        _row('Tổng', total, bold: true),
      ],
    );
  }

  Widget _row(String label, double value, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(
              CurrencyFormatter.formatVnd(value),
              style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
            ),
          ],
        ),
      );
}
