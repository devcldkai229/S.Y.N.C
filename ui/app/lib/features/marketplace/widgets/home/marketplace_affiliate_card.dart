import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';
import 'package:sync_app/features/marketplace/widgets/marketplace_network_image.dart';

class MarketplaceAffiliateCard extends StatelessWidget {
  const MarketplaceAffiliateCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  final AffiliateProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrls.isNotEmpty ? product.imageUrls.first : null;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: MarketplaceTheme.affiliateBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MarketplaceTheme.affiliateBorder, style: BorderStyle.solid),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? MarketplaceNetworkImage(
                      imageUrl: imageUrl,
                      assetFallback: MarketplaceCatalog.dishPlaceholder,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: MarketplaceTheme.border,
                      child: const Icon(Icons.link_rounded, color: MarketplaceTheme.textMuted),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: MarketplaceTheme.affiliateBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Liên kết đối tác',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MarketplaceTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(product.nameVi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(product.brandName, style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted)),
                  const SizedBox(height: 4),
                  Text(
                    MarketplaceFormatters.formatVnd(product.price),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: MarketplaceTheme.primary),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onTap,
                      style: TextButton.styleFrom(
                        foregroundColor: MarketplaceTheme.textMuted,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text('Xem tại ${product.brandName} ↗', style: const TextStyle(fontWeight: FontWeight.w700)),
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
