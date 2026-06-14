import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/mock/marketplace_mock_data.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';

class MarketplaceMockRepository implements MarketplaceRepository {
  @override
  Future<MarketplaceHomeData> loadHome({
    double? lat,
    double? lng,
    String? categoryId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    return MarketplaceMockData.buildHome(categoryId: categoryId);
  }

  @override
  Future<void> trackAffiliateClick(String productId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }
}
