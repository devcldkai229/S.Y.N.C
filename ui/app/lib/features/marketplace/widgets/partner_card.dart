import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

class PartnerCard extends StatelessWidget {
  const PartnerCard({super.key, required this.partner, required this.onTap});

  final Partner partner;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: MarketplaceTheme.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (partner.coverImageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: CachedNetworkImage(
                  imageUrl: partner.coverImageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(partner.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          '★ ${partner.ratingAverage.toStringAsFixed(1)} · ${partner.distanceKm?.toStringAsFixed(1) ?? '?'} km',
                          style: const TextStyle(color: MarketplaceTheme.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: partner.isOpenNow ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      partner.isOpenNow ? 'Đang mở' : 'Đóng',
                      style: TextStyle(
                        fontSize: 12,
                        color: partner.isOpenNow ? Colors.green.shade800 : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
