import 'dart:math';

import 'package:sync_app/features/marketplace/data/marketplace_catalog.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

/// Static marketplace catalog for UI development.
abstract final class MarketplaceMockData {
  static const defaultLat = 10.7769;
  static const defaultLng = 106.7009;

  static const categories = <CategoryItem>[
    CategoryItem(id: 'healthy', label: 'Healthy'),
    CategoryItem(id: 'eat-clean', label: 'Eat Clean'),
    CategoryItem(id: 'high-protein', label: 'High-Protein'),
    CategoryItem(id: 'salad', label: 'Salad'),
    CategoryItem(id: 'com', label: 'Cơm'),
    CategoryItem(id: 'combo', label: 'Combo'),
    CategoryItem(id: 'low-carb', label: 'Low-carb'),
    CategoryItem(id: 'drinks', label: 'Đồ uống'),
  ];

  static final shortcuts = <ShortcutItem>[
    ...MarketplaceCatalog.shortcuts,
    ShortcutItem(
      id: 'variety',
      title: 'Healthy',
      subtitle: 'Đổi vị',
      imageUrl: 'https://picsum.photos/seed/sync-short-variety/280/160',
      filterTag: 'healthy',
    ),
  ];

  static final _partners = <Partner>[
    Partner(
      id: 'p1',
      name: 'Green Bowl Kitchen',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p1/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p1/800/400',
      description: 'Eat clean & salad bowls',
      ratingAverage: 4.8,
      ratingCount: 120,
      distanceKm: 1.2,
      status: 'Active',
      address: '12 Lê Lợi, Quận 1, TP.HCM',
    ),
    Partner(
      id: 'p2',
      name: 'Protein House',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p2/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p2/800/400',
      ratingAverage: 4.7,
      ratingCount: 86,
      distanceKm: 2.4,
      status: 'Active',
      address: '88 Nguyễn Thị Minh Khai, Quận 3',
    ),
    Partner(
      id: 'p3',
      name: 'Fit Meal Saigon',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p3/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p3/800/400',
      ratingAverage: 4.9,
      ratingCount: 203,
      distanceKm: 0.8,
      status: 'Active',
      address: '5 Pasteur, Quận 1',
    ),
    Partner(
      id: 'p4',
      name: 'Low Carb Lab',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p4/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p4/800/400',
      ratingAverage: 4.6,
      ratingCount: 54,
      distanceKm: 3.1,
      status: 'Active',
      address: '220 Võ Văn Tần, Quận 3',
    ),
    Partner(
      id: 'p5',
      name: 'SYNC Demo Kitchen',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p5/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p5/800/400',
      ratingAverage: 4.5,
      ratingCount: 42,
      distanceKm: 1.9,
      status: 'Inactive',
      address: 'Demo Partner Address',
    ),
    Partner(
      id: 'p6',
      name: 'Clean Bites',
      logoUrl: 'https://picsum.photos/seed/sync-logo-p6/80/80',
      coverImageUrl: 'https://picsum.photos/seed/sync-kitchen-p6/800/400',
      ratingAverage: 4.8,
      ratingCount: 97,
      distanceKm: 2.0,
      status: 'Active',
      address: '15 Hai Bà Trưng, Quận 1',
    ),
  ];

  static List<KitchenCardVm> get kitchens => [
        KitchenCardVm(
          partner: _partners[0],
          deliveryFee: 15000,
          etaMin: 25,
          etaMax: 35,
          tags: const ['Healthy', 'Eat Clean'],
          promoLabel: '-20% đơn đầu',
        ),
        KitchenCardVm(
          partner: _partners[1],
          deliveryFee: 18000,
          etaMin: 30,
          etaMax: 40,
          tags: const ['High-Protein'],
        ),
        KitchenCardVm(
          partner: _partners[2],
          deliveryFee: 12000,
          etaMin: 20,
          etaMax: 30,
          tags: const ['Healthy', 'Combo'],
          promoLabel: 'Freeship 2km',
        ),
        KitchenCardVm(
          partner: _partners[3],
          deliveryFee: 20000,
          etaMin: 35,
          etaMax: 45,
          tags: const ['Low-carb'],
        ),
        KitchenCardVm(
          partner: _partners[4],
          deliveryFee: 25000,
          etaMin: 40,
          etaMax: 50,
          tags: const ['Eat Clean'],
        ),
        KitchenCardVm(
          partner: _partners[5],
          deliveryFee: 15000,
          etaMin: 25,
          etaMax: 35,
          tags: const ['Salad', 'Healthy'],
        ),
      ];

  static final _dishes = <({FoodMenuItem item, String partnerName, String imageUrl})>[
    (
      item: FoodMenuItem(
        id: 'f1',
        partnerId: 'p1',
        nameVi: 'Salad Gà Nướng',
        description: 'Rau xanh, gà nướng, sốt yogurt',
        imageUrls: const [],
        price: 89000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 420, proteinGram: 35, carbGram: 28, fatGram: 12),
        category: 'Salad',
        dietaryTags: const ['Healthy', 'High-Protein'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.8,
        ratingCount: 120,
        prepTimeMinutes: 15,
      ),
      partnerName: 'Green Bowl Kitchen',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f1/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f2',
        partnerId: 'p2',
        nameVi: 'Cơm Gà Ác Xuyên',
        description: 'Gạo lứt, ức gà, rau củ',
        imageUrls: const [],
        price: 75000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 510, proteinGram: 42, carbGram: 45, fatGram: 10),
        category: 'Cơm',
        dietaryTags: const ['High-Protein'],
        spiceLevel: 'Medium',
        availability: 'Available',
        ratingAverage: 4.7,
        ratingCount: 86,
        prepTimeMinutes: 20,
      ),
      partnerName: 'Protein House',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f2/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f3',
        partnerId: 'p3',
        nameVi: 'Bowl Bí Đỏ Hạt Chia',
        description: 'Bí đỏ, quinoa, hạt chia',
        imageUrls: const [],
        price: 68000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 380, proteinGram: 18, carbGram: 40, fatGram: 14),
        category: 'Healthy',
        dietaryTags: const ['Eat Clean', 'Vegan'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.9,
        ratingCount: 203,
        prepTimeMinutes: 12,
      ),
      partnerName: 'Fit Meal Saigon',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f3/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f4',
        partnerId: 'p1',
        nameVi: 'Wrap Bò Bằm',
        description: 'Bánh tortilla ngũ cốc, bò lean',
        imageUrls: const [],
        price: 92000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 450, proteinGram: 38, carbGram: 32, fatGram: 16),
        category: 'Combo',
        dietaryTags: const ['High-Protein'],
        spiceLevel: 'Medium',
        availability: 'Available',
        ratingAverage: 4.6,
        ratingCount: 54,
        prepTimeMinutes: 18,
      ),
      partnerName: 'Green Bowl Kitchen',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f4/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f5',
        partnerId: 'p4',
        nameVi: 'Mì Zucchini Pesto',
        description: 'Low-carb, pesto hạt điều',
        imageUrls: const [],
        price: 85000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 340, proteinGram: 22, carbGram: 18, fatGram: 20),
        category: 'Low-carb',
        dietaryTags: const ['Low-carb'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.5,
        ratingCount: 42,
        prepTimeMinutes: 16,
      ),
      partnerName: 'Low Carb Lab',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f5/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f6',
        partnerId: 'p3',
        nameVi: 'Smoothie Xanh Detox',
        description: 'Cải xoăn, táo, gừng',
        imageUrls: const [],
        price: 55000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 180, proteinGram: 6, carbGram: 32, fatGram: 2),
        category: 'Đồ uống',
        dietaryTags: const ['Healthy'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.8,
        ratingCount: 97,
        prepTimeMinutes: 8,
      ),
      partnerName: 'Fit Meal Saigon',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f6/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f7',
        partnerId: 'p6',
        nameVi: 'Cá Hồi Teriyaki',
        description: 'Cá hồi, cơm lứt, edamame',
        imageUrls: const [],
        price: 125000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 520, proteinGram: 40, carbGram: 38, fatGram: 18),
        category: 'Cơm',
        dietaryTags: const ['High-Protein', 'Eat Clean'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.9,
        ratingCount: 156,
        prepTimeMinutes: 22,
      ),
      partnerName: 'Clean Bites',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f7/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f8',
        partnerId: 'p2',
        nameVi: 'Ức Gà Sous-vide',
        description: 'Ức gà, khoai lang, bông cải',
        imageUrls: const [],
        price: 98000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 410, proteinGram: 45, carbGram: 25, fatGram: 8),
        category: 'High-Protein',
        dietaryTags: const ['High-Protein'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.7,
        ratingCount: 72,
        prepTimeMinutes: 18,
      ),
      partnerName: 'Protein House',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f8/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f9',
        partnerId: 'p1',
        nameVi: 'Poke Bowl Cá Ngừ',
        description: 'Cá ngừ, avocado, gạo lứt',
        imageUrls: const [],
        price: 105000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 470, proteinGram: 36, carbGram: 42, fatGram: 15),
        category: 'Healthy',
        dietaryTags: const ['Healthy'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.8,
        ratingCount: 88,
        prepTimeMinutes: 14,
      ),
      partnerName: 'Green Bowl Kitchen',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f9/400/300',
    ),
    (
      item: FoodMenuItem(
        id: 'f10',
        partnerId: 'p6',
        nameVi: 'Soup Rau Củ Nấm',
        description: 'Soup detox, nấm shiitake',
        imageUrls: const [],
        price: 62000,
        currency: 'VND',
        nutrition: const NutritionSnapshot(calories: 220, proteinGram: 12, carbGram: 28, fatGram: 6),
        category: 'Eat Clean',
        dietaryTags: const ['Eat Clean', 'Vegan'],
        spiceLevel: 'Mild',
        availability: 'Available',
        ratingAverage: 4.6,
        ratingCount: 45,
        prepTimeMinutes: 10,
      ),
      partnerName: 'Clean Bites',
      imageUrl: 'https://picsum.photos/seed/sync-dish-f10/400/300',
    ),
  ];

  static List<FeaturedDishVm> get featured =>
      _dishes.map((d) => FeaturedDishVm(item: d.item, partnerName: d.partnerName, imageUrl: d.imageUrl)).toList();

  static final affiliate = <AffiliateProduct>[
    AffiliateProduct(
      id: 'a1',
      brandName: 'Optimum Nutrition',
      nameVi: 'Gold Standard Whey 2.27kg',
      description: 'Whey protein isolate blend',
      imageUrls: const ['https://picsum.photos/seed/sync-aff-a1/200/200'],
      price: 890000,
      currency: 'VND',
      affiliateUrl: 'https://example.com/on-whey',
      nutrition: const NutritionSnapshot(calories: 120, proteinGram: 24, carbGram: 3, fatGram: 1),
      ratingAverage: 4.9,
      ratingCount: 342,
    ),
    AffiliateProduct(
      id: 'a2',
      brandName: 'MyProtein',
      nameVi: 'Impact Whey Isolate 1kg',
      description: 'Isolate cao, ít lactose',
      imageUrls: const ['https://picsum.photos/seed/sync-aff-a2/200/200'],
      price: 650000,
      currency: 'VND',
      affiliateUrl: 'https://example.com/myprotein',
      ratingAverage: 4.7,
      ratingCount: 198,
    ),
    AffiliateProduct(
      id: 'a3',
      brandName: 'DHC',
      nameVi: 'Omega-3 Fish Oil',
      description: 'DHA/EPA hỗ trợ tim mạch',
      imageUrls: const ['https://picsum.photos/seed/sync-aff-a3/200/200'],
      price: 320000,
      currency: 'VND',
      affiliateUrl: 'https://example.com/dhc-omega',
      ratingAverage: 4.6,
      ratingCount: 87,
    ),
    AffiliateProduct(
      id: 'a4',
      brandName: 'Now Foods',
      nameVi: 'Creatine Monohydrate 500g',
      description: 'Creatine tinh khiết',
      imageUrls: const ['https://picsum.photos/seed/sync-aff-a4/200/200'],
      price: 450000,
      currency: 'VND',
      affiliateUrl: 'https://example.com/now-creatine',
      ratingAverage: 4.8,
      ratingCount: 156,
    ),
  ];

  static PartnerDetail? partnerDetail(String id) {
    Partner? partner;
    for (final p in _partners) {
      if (p.id == id) {
        partner = p;
        break;
      }
    }
    if (partner == null) return null;

    final menu = _dishes
        .where((d) => d.item.partnerId == id)
        .map((d) => d.item)
        .toList();

    return PartnerDetail(
      id: partner.id,
      name: partner.name,
      logoUrl: partner.logoUrl,
      coverImageUrl: partner.coverImageUrl,
      description: partner.description,
      ratingAverage: partner.ratingAverage,
      ratingCount: partner.ratingCount,
      distanceKm: partner.distanceKm,
      status: partner.status,
      address: partner.address,
      menu: menu,
    );
  }

  static FoodMenuItem? foodMenuItem(String id) {
    for (final d in _dishes) {
      if (d.item.id == id) return d.item;
    }
    return null;
  }

  static String? partnerNameForFood(String foodId) {
    for (final d in _dishes) {
      if (d.item.id == foodId) return d.partnerName;
    }
    return null;
  }

  static List<FeaturedDishVm> pickRandomFeatured({int count = 10}) {
    final pool = [...featured]..shuffle(Random());
    return pool.take(count).toList();
  }

  static MarketplaceHomeData buildHome({String? categoryId}) {
    final featuredList = pickRandomFeatured();
    var kitchenList = kitchens;

    if (categoryId != null && categoryId != 'all') {
      final tag = categoryId.replaceAll('-', ' ');
      kitchenList = kitchens
          .where((k) => k.tags.any((t) => t.toLowerCase().contains(tag.split(' ').first)))
          .toList();
      if (kitchenList.isEmpty) kitchenList = kitchens;
    }

    return MarketplaceHomeData(
      categories: categories,
      shortcuts: shortcuts,
      featured: featuredList,
      kitchens: kitchenList,
      affiliate: affiliate,
    );
  }

  /// Mock reverse-geocode lookup near HCMC.
  static String mockAddressFor(double lat, double lng) {
    if (lat >= 10.772 && lat <= 10.778 && lng >= 106.698 && lng <= 106.704) {
      return '47 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP.HCM';
    }
    if (lat >= 10.778 && lat <= 10.785) {
      return '88 Nguyễn Thị Minh Khai, Quận 3, TP.HCM';
    }
    if (lat >= 10.765 && lat < 10.772) {
      return '220 Võ Văn Tần, Quận 3, TP.HCM';
    }
    return 'Quận 1, TP.HCM';
  }

  static String shortenAddress(String full) {
    final parts = full.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[parts.length - 2].trim()}';
    }
    return full.length > 32 ? '${full.substring(0, 29)}…' : full;
  }
}
