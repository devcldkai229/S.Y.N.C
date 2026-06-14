import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';

abstract class MarketplaceRepository {
  Future<MarketplaceHomeData> loadHome({
    double? lat,
    double? lng,
    String? categoryId,
  });

  Future<List<KitchenCardVm>> loadListing({
    required MarketplaceListingFilter filter,
    double? lat,
    double? lng,
  });

  Future<MarketplaceSearchResult> search({
    required String query,
    double? lat,
    double? lng,
  });

  Future<void> trackAffiliateClick(String productId);
}
