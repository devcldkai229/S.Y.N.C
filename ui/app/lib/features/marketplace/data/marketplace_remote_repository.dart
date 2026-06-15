import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/data/marketplace_repository.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_listing_filter.dart';
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
    final partnersFuture = _searchPartnersWithFallback(lat: lat, lng: lng);
    final suggestionsFuture = _api.getFoodSuggestions(count: 10, lat: lat, lng: lng);
    final affiliateFuture = _api.searchAffiliate();
    final deliveryFeeFuture = _deliveryFee.load();

    final results = await Future.wait([partnersFuture, suggestionsFuture, affiliateFuture, deliveryFeeFuture]);
    final partners = results[0] as List<Partner>;
    final dishes = results[1] as List<FoodMenuItem>;
    final affiliate = results[2] as List<AffiliateProduct>;
    final deliveryFee = results[3] as double;

    final partnerNames = {for (final p in partners) p.id: p.name};

    final kitchens = _toKitchenCards(partners, deliveryFee, const ['Healthy']);

    final featured = dishes
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
  Future<List<KitchenCardVm>> loadListing({
    required MarketplaceListingFilter filter,
    double? lat,
    double? lng,
  }) async {
    final deliveryFee = await _deliveryFee.load();
    final tags = _tagsForFilter(filter);

    List<Partner> partners;

    if (filter.nearbyOnly) {
      partners = await _searchPartnersWithFallback(lat: lat, lng: lng, radiusKm: 8, pageSize: 40);
    } else if (filter.macroBalanced) {
      final dishes = await _searchFoodWithFallback(lat: lat, lng: lng, pageSize: 80);
      partners = await _partnersFromDishes(
        dishes.where(_isMacroBalanced).toList(),
        lat: lat,
        lng: lng,
      );
      if (partners.isEmpty) {
        partners = await _searchPartnersWithFallback(pageSize: 40);
      }
    } else if (filter.healthyCollection) {
      var dishes = await _searchFoodWithFallback(
        dietaryTags: const ['LowFat'],
        lat: lat,
        lng: lng,
        pageSize: 60,
      );
      if (dishes.isEmpty) {
        dishes = await _searchFoodWithFallback(
          dietaryTags: const ['HighProtein'],
          lat: lat,
          lng: lng,
          pageSize: 60,
        );
      }
      partners = await _partnersFromDishes(dishes, lat: lat, lng: lng);
      if (partners.isEmpty) {
        partners = await _searchPartnersWithFallback(pageSize: 40);
      }
    } else if (filter.categoryId != null) {
      final params = MarketplaceCatalog.searchParamsForCategory(filter.categoryId);
      if (params != null && params['macroBalanced'] == true) {
        final dishes = await _searchFoodWithFallback(lat: lat, lng: lng, pageSize: 80);
        partners = await _partnersFromDishes(
          dishes.where(_isMacroBalanced).toList(),
          lat: lat,
          lng: lng,
        );
        if (partners.isEmpty) {
          partners = await _searchPartnersWithFallback(pageSize: 40);
        }
      } else {
        final tags = (params?['dietaryTags'] as List?)?.cast<String>();
        final category = params?['category'] as String?;
        final dishes = await _searchFoodWithFallback(
          category: category,
          dietaryTags: tags,
          lat: lat,
          lng: lng,
          pageSize: 80,
        );
        partners = await _partnersFromDishes(dishes, lat: lat, lng: lng);
        if (partners.isEmpty) {
          partners = await _searchPartnersWithFallback(pageSize: 40);
        }
      }
    } else {
      partners = await _searchPartnersWithFallback(lat: lat, lng: lng, pageSize: 40);
    }

    return _toKitchenCards(partners, deliveryFee, tags);
  }

  @override
  Future<MarketplaceSearchResult> search({
    required String query,
    double? lat,
    double? lng,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      return const MarketplaceSearchResult(partners: [], dishes: []);
    }

    final partnersFuture = _searchPartnersWithFallback(
      query: q,
      lat: lat,
      lng: lng,
      pageSize: 30,
    );
    final dishesFuture = _searchFoodWithFallback(
      query: q,
      lat: lat,
      lng: lng,
      pageSize: 30,
    );

    final results = await Future.wait([partnersFuture, dishesFuture]);
    final partners = results[0] as List<Partner>;
    final dishes = results[1] as List<FoodMenuItem>;

    final partnerHits = partners
        .map((p) => PartnerSearchHit(id: p.id, name: p.name, distanceKm: p.distanceKm))
        .toList();

    return MarketplaceSearchResult(partners: partnerHits, dishes: dishes);
  }

  @override
  Future<void> trackAffiliateClick(String productId) async {
    await _api.trackAffiliateClick(productId);
  }

  Future<List<Partner>> _searchPartnersWithFallback({
    String? query,
    double? lat,
    double? lng,
    double radiusKm = 10,
    int pageSize = 20,
  }) async {
    final partners = await _api.searchPartners(
      query: query,
      lat: lat,
      lng: lng,
      radiusKm: radiusKm,
      pageSize: pageSize,
    );
    if (partners.isNotEmpty || lat == null || lng == null) return partners;
    return _api.searchPartners(query: query, pageSize: pageSize);
  }

  Future<List<FoodMenuItem>> _searchFoodWithFallback({
    String? query,
    String? category,
    List<String>? dietaryTags,
    double? lat,
    double? lng,
    int pageSize = 20,
  }) async {
    final items = await _api.searchFoodMenu(
      query: query,
      category: category,
      dietaryTags: dietaryTags,
      lat: lat,
      lng: lng,
      pageSize: pageSize,
    );
    if (items.isNotEmpty || lat == null || lng == null) return items;
    return _api.searchFoodMenu(
      query: query,
      category: category,
      dietaryTags: dietaryTags,
      pageSize: pageSize,
    );
  }

  Future<List<Partner>> _partnersFromDishes(
    List<FoodMenuItem> dishes, {
    double? lat,
    double? lng,
  }) async {
    final ids = dishes.map((d) => d.partnerId).toSet();
    if (ids.isEmpty) return [];

    var partners = <Partner>[];
    if (lat != null && lng != null) {
      final nearby = await _searchPartnersWithFallback(lat: lat, lng: lng, radiusKm: 15, pageSize: 50);
      partners = nearby.where((p) => ids.contains(p.id)).toList();
    }

    if (partners.length < ids.length) {
      final all = await _api.searchPartners(pageSize: 100);
      for (final p in all) {
        if (ids.contains(p.id) && !partners.any((x) => x.id == p.id)) {
          partners.add(p);
        }
      }
    }

    partners.sort((a, b) {
      final da = a.distanceKm ?? double.infinity;
      final db = b.distanceKm ?? double.infinity;
      return da.compareTo(db);
    });
    return partners;
  }

  List<KitchenCardVm> _toKitchenCards(
    List<Partner> partners,
    double deliveryFee,
    List<String> tags,
  ) {
    final sorted = [...partners]
      ..sort((a, b) {
        final da = a.distanceKm ?? double.infinity;
        final db = b.distanceKm ?? double.infinity;
        return da.compareTo(db);
      });

    return sorted
        .map((p) => KitchenCardVm(
              partner: p,
              deliveryFee: deliveryFee,
              etaMin: 20 + (p.distanceKm ?? 1).round(),
              etaMax: 35 + (p.distanceKm ?? 1).round(),
              tags: tags,
            ))
        .toList();
  }

  static bool _isMacroBalanced(FoodMenuItem item) {
    final n = item.nutrition;
    return n.proteinGram >= 15 && n.carbGram >= 15 && n.fatGram >= 5;
  }

  static List<String> _tagsForFilter(MarketplaceListingFilter filter) {
    if (filter.nearbyOnly) return const ['Gần bạn'];
    if (filter.macroBalanced) return const ['Đủ dinh dưỡng'];
    if (filter.healthyCollection) return const ['Healthy'];
    if (filter.categoryId != null) {
      return [MarketplaceCatalog.labelForCategoryId(filter.categoryId)];
    }
    return const ['Quán'];
  }
}
