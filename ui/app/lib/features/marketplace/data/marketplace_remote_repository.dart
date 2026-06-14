import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';
import 'package:sync_app/features/order/state/delivery_fee_config.dart';

class MarketplaceRemoteRepository implements MarketplaceRepository {
  MarketplaceRemoteRepository(this._api, this._deliveryFee);

  final MarketplaceRemoteDataSource _api;
  final DeliveryFeeConfig _deliveryFee;

  @override
  Future<MarketplaceHomeData> loadHome({
    double? lat,
    double? lng,
    String? categoryId,
  }) async {
    final searchParams = MarketplaceCatalog.searchParamsForCategory(categoryId);

    final partnersFuture = _api.searchPartners(lat: lat, lng: lng);
    final foodFuture = _api.searchFoodMenu(
      lat: lat,
      lng: lng,
      category: searchParams?['category'] as String?,
      dietaryTags: (searchParams?['dietaryTags'] as List<String>?),
    );
    final affiliateFuture = _api.searchAffiliate();
    final deliveryFeeFuture = _deliveryFee.load();

    final results = await Future.wait([partnersFuture, foodFuture, affiliateFuture, deliveryFeeFuture]);
    final partners = results[0] as List<Partner>;
    final dishes = results[1] as List<FoodMenuItem>;
    final affiliate = results[2] as List<AffiliateProduct>;
    final deliveryFee = results[3] as double;

    final partnerNames = {for (final p in partners) p.id: p.name};

    final sortedPartners = [...partners]
      ..sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });

    final kitchens = sortedPartners
        .map((p) => KitchenCardVm(
              partner: p,
              deliveryFee: deliveryFee,
              etaMin: 20 + (p.distanceKm ?? 1).round(),
              etaMax: 35 + (p.distanceKm ?? 1).round(),
              tags: const ['Healthy'],
            ))
        .toList();

    final featured = dishes
        .take(12)
        .map((item) => FeaturedDishVm(
              item: item,
              partnerName: partnerNames[item.partnerId] ?? 'Bếp',
              imageUrl: item.imageUrls.isNotEmpty
                  ? item.imageUrls.first
                  : MarketplaceCatalog.dishPlaceholder,
            ))
        .toList();

    return MarketplaceHomeData(
      categories: MarketplaceCatalog.categories,
      shortcuts: MarketplaceCatalog.shortcuts,
      featured: featured,
      kitchens: kitchens,
      affiliate: affiliate,
    );
  }

  @override
  Future<void> trackAffiliateClick(String productId) async {
    await _api.trackAffiliateClick(productId);
  }
}
