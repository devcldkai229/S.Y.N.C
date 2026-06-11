import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:url_launcher/url_launcher.dart';

class ShipperCard extends StatelessWidget {
  const ShipperCard({super.key, required this.tracking});

  final DeliveryTracking tracking;

  Future<void> _call() async {
    final phone = tracking.shipperPhone;
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (tracking.shipperName == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: MarketplaceTheme.cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(child: Icon(Icons.delivery_dining)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tracking.shipperName!, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (tracking.shipperPlateNumber != null)
                  Text(tracking.shipperPlateNumber!, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            onPressed: _call,
            icon: const Icon(Icons.phone, color: MarketplaceTheme.primary),
          ),
        ],
      ),
    );
  }
}
