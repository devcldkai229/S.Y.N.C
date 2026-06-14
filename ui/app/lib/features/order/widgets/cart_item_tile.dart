import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/currency_formatter.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.line,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final CartLine line;
  final ValueChanged<int> onQtyChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5EAE3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(CurrencyFormatter.formatVnd(line.unitPrice)),
              ],
            ),
          ),
          IconButton(onPressed: () => onQtyChanged(line.quantity - 1), icon: const Icon(Icons.remove)),
          Text('${line.quantity}'),
          IconButton(onPressed: () => onQtyChanged(line.quantity + 1), icon: const Icon(Icons.add)),
          IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
        ],
      ),
    );
  }
}
