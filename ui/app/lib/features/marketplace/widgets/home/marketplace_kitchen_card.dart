import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';

class MarketplaceKitchenCard extends StatelessWidget {
  const MarketplaceKitchenCard({super.key, required this.kitchen, required this.onTap});

  final KitchenCardVm kitchen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = kitchen.partner;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: MarketplaceTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: p.coverImageUrl ?? 'https://picsum.photos/seed/sync-kitchen-fallback/800/320',
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _StatusBadge(isOpen: p.isOpen),
                ),
                if (kitchen.promoLabel != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: MarketplaceTheme.limeChip,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kitchen.promoLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: MarketplaceTheme.primaryDark,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: p.logoUrl ?? 'https://picsum.photos/seed/sync-logo-fallback/80/80',
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          '${MarketplaceFormatters.formatRating(p.ratingAverage, p.ratingCount)} · '
                          '${MarketplaceFormatters.formatKm(p.distanceKm)} · '
                          '${kitchen.etaMin}–${kitchen.etaMax} phút',
                          style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ship ${MarketplaceFormatters.formatVnd(kitchen.deliveryFee)}',
                          style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: kitchen.tags
                              .map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: MarketplaceTheme.lightGreen,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: MarketplaceTheme.primary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.white : Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isOpen ? 'Đang mở' : 'Đóng cửa',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOpen ? MarketplaceTheme.primary : Colors.white70,
        ),
      ),
    );
  }
}
