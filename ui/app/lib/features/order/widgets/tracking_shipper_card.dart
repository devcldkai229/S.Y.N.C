import 'package:flutter/material.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackingShipperCard extends StatelessWidget {
  const TrackingShipperCard({super.key, required this.shipper});

  final ShipperInfo shipper;

  Future<void> _call() async {
    final phone = shipper.phone;
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: OrderTheme.cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: OrderTheme.line,
            child: Icon(Icons.person_outline, color: OrderTheme.textMuted.withValues(alpha: 0.8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(shipper.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text(
                  shipper.plateNumber,
                  style: const TextStyle(fontSize: 13, color: OrderTheme.textMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: shipper.phone != null ? _call : null,
            icon: const Icon(Icons.phone_outlined, color: OrderTheme.accent),
            tooltip: 'Gọi shipper',
          ),
        ],
      ),
    );
  }
}
