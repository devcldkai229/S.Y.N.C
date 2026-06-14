import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';

abstract class MarketplaceRepository {
  Future<MarketplaceHomeData> loadHome({
    double? lat,
    double? lng,
    String? categoryId,
  });

  Future<void> trackAffiliateClick(String productId);
}
