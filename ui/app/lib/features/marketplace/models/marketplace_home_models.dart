import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

class CategoryItem {
  const CategoryItem({
    required this.id,
    required this.label,
    this.imageUrl = '',
  });

  final String id;
  final String label;
  final String imageUrl;
}

class ShortcutItem {
  const ShortcutItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.filterTag,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String? filterTag;
}

class FeaturedDishVm {
  const FeaturedDishVm({
    required this.item,
    required this.partnerName,
    required this.imageUrl,
  });

  final FoodMenuItem item;
  final String partnerName;
  final String imageUrl;
}

class KitchenCardVm {
  const KitchenCardVm({
    required this.partner,
    required this.deliveryFee,
    required this.etaMin,
    required this.etaMax,
    required this.tags,
    this.promoLabel,
  });

  final Partner partner;
  final double deliveryFee;
  final int etaMin;
  final int etaMax;
  final List<String> tags;
  final String? promoLabel;
}

class MarketplaceHomeData {
  const MarketplaceHomeData({
    required this.categories,
    required this.shortcuts,
    required this.featured,
    required this.kitchens,
    required this.affiliate,
  });

  final List<CategoryItem> categories;
  final List<ShortcutItem> shortcuts;
  final List<FeaturedDishVm> featured;
  final List<KitchenCardVm> kitchens;
  final List<AffiliateProduct> affiliate;
}

class DeliveryLocation {
  const DeliveryLocation({
    required this.lat,
    required this.lng,
    required this.shortLabel,
    required this.fullAddress,
  });

  final double lat;
  final double lng;
  final String shortLabel;
  final String fullAddress;
}
