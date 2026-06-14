import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

/// Arguments for [MarketplaceListingScreen].
class MarketplaceListingFilter {
  const MarketplaceListingFilter({
    required this.title,
    this.categoryId,
    this.nearbyOnly = false,
    this.macroBalanced = false,
    this.healthyCollection = false,
  });

  final String title;
  final String? categoryId;
  final bool nearbyOnly;
  final bool macroBalanced;
  final bool healthyCollection;

  static const nearby = MarketplaceListingFilter(
    title: 'Gần bạn',
    nearbyOnly: true,
  );

  static const all = MarketplaceListingFilter(title: 'Tất cả quán');

  static const healthy = MarketplaceListingFilter(
    title: 'Ăn healthy, giao nhanh',
    healthyCollection: true,
  );

  static const suggestions = MarketplaceListingFilter(title: 'Gợi ý cho bạn');

  static MarketplaceListingFilter forCategory(String categoryId, String label) =>
      MarketplaceListingFilter(title: label, categoryId: categoryId);

  static const macro = MarketplaceListingFilter(
    title: 'Đủ dinh dưỡng',
    macroBalanced: true,
  );

  static const highProtein = MarketplaceListingFilter(
    title: 'Protein cao',
    categoryId: 'high-protein',
  );
}

class MarketplaceSearchResult {
  const MarketplaceSearchResult({
    required this.partners,
    required this.dishes,
  });

  final List<PartnerSearchHit> partners;
  final List<FoodMenuItem> dishes;
}

class PartnerSearchHit {
  const PartnerSearchHit({required this.id, required this.name, this.distanceKm});

  final String id;
  final String name;
  final double? distanceKm;
}
