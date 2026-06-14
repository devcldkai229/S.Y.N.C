import 'package:flutter/material.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final AffiliateProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: MarketplaceTheme.cardDecoration(),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: MarketplaceTheme.border,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: MarketplaceTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nameVi, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(product.brandName, style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted)),
                  Text('${product.price.toStringAsFixed(0)} ${product.currency}',
                      style: const TextStyle(color: MarketplaceTheme.primary)),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: const Text('Mua')),
          ],
        ),
      ),
    );
  }
}
