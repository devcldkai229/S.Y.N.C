import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/utils/marketplace_formatters.dart';

class MarketplaceFeaturedRow extends StatelessWidget {
  const MarketplaceFeaturedRow({super.key, required this.dishes, required this.onDishTap});

  final List<FeaturedDishVm> dishes;
  final ValueChanged<FeaturedDishVm> onDishTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 228,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: dishes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => MarketplaceFeaturedDishCard(
          dish: dishes[i],
          onTap: () => onDishTap(dishes[i]),
        ),
      ),
    );
  }
}

class MarketplaceFeaturedDishCard extends StatelessWidget {
  const MarketplaceFeaturedDishCard({super.key, required this.dish, required this.onTap});

  final FeaturedDishVm dish;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final item = dish.item;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 168,
        decoration: MarketplaceTheme.cardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Hero(
                  tag: 'marketplace-food-${item.id}',
                  child: CachedNetworkImage(
                    imageUrl: dish.imageUrl,
                    height: 108,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MarketplaceTheme.limeChip,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.nutrition.calories} kcal',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: MarketplaceTheme.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameVi,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    MarketplaceFormatters.formatVnd(item.price),
                    style: const TextStyle(
                      color: MarketplaceTheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dish.partnerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: MarketplaceTheme.textMuted),
                  ),
                  Text(
                    MarketplaceFormatters.formatRating(item.ratingAverage, item.ratingCount),
                    style: const TextStyle(fontSize: 11, color: MarketplaceTheme.textMuted),
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
