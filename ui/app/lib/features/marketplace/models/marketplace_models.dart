import 'package:sync_app/features/marketplace/utils/marketplace_partner_hours.dart';

class NutritionSnapshot {
  const NutritionSnapshot({
    required this.calories,
    required this.proteinGram,
    required this.carbGram,
    required this.fatGram,
  });

  final int calories;
  final double proteinGram;
  final double carbGram;
  final double fatGram;

  factory NutritionSnapshot.fromJson(Map<String, dynamic>? json) => NutritionSnapshot(
        calories: (json?['calories'] as num?)?.toInt() ?? 0,
        proteinGram: (json?['proteinGram'] as num?)?.toDouble() ?? 0,
        carbGram: (json?['carbGram'] as num?)?.toDouble() ?? 0,
        fatGram: (json?['fatGram'] as num?)?.toDouble() ?? 0,
      );
}

class PartnerLocation {
  const PartnerLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory PartnerLocation.fromJson(Map<String, dynamic>? json) => PartnerLocation(
        latitude: (json?['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json?['longitude'] as num?)?.toDouble() ?? 0,
      );
}

class OperatingHour {
  const OperatingHour({
    required this.dayOfWeek,
    required this.openTime,
    required this.closeTime,
    required this.isClosed,
  });

  final int dayOfWeek;
  final String openTime;
  final String closeTime;
  final bool isClosed;

  factory OperatingHour.fromJson(Map<String, dynamic> json) => OperatingHour(
        dayOfWeek: (json['dayOfWeek'] as num?)?.toInt() ?? 0,
        openTime: json['openTime']?.toString() ?? '',
        closeTime: json['closeTime']?.toString() ?? '',
        isClosed: json['isClosed'] == true,
      );
}

class Partner {
  const Partner({
    required this.id,
    required this.name,
    this.logoUrl,
    this.coverImageUrl,
    this.description,
    required this.ratingAverage,
    required this.ratingCount,
    this.distanceKm,
    required this.status,
    this.address,
    this.location,
    this.operatingHours = const [],
  });

  final String id;
  final String name;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? description;
  final double ratingAverage;
  final int ratingCount;
  final double? distanceKm;
  final String status;
  final String? address;
  final PartnerLocation? location;
  final List<OperatingHour> operatingHours;

  bool get isOpenNow => MarketplacePartnerHours.isOpenNow(operatingHours);

  factory Partner.fromJson(Map<String, dynamic> json) {
    final hoursRaw = json['operatingHours'];
    return Partner(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      logoUrl: json['logoUrl']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString(),
      description: json['description']?.toString(),
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'Active',
      address: json['address']?.toString(),
      location: json['location'] is Map<String, dynamic>
          ? PartnerLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      operatingHours: hoursRaw is List
          ? hoursRaw.whereType<Map<String, dynamic>>().map(OperatingHour.fromJson).toList()
          : const [],
    );
  }
}

class PartnerDetail extends Partner {
  const PartnerDetail({
    required super.id,
    required super.name,
    super.logoUrl,
    super.coverImageUrl,
    super.description,
    required super.ratingAverage,
    required super.ratingCount,
    super.distanceKm,
    required super.status,
    super.address,
    super.location,
    super.operatingHours,
    required this.menu,
  });

  final List<FoodMenuItem> menu;

  factory PartnerDetail.fromJson(Map<String, dynamic> json) {
    final menuRaw = json['menu'];
    final base = Partner.fromJson(json);
    return PartnerDetail(
      id: base.id,
      name: base.name,
      logoUrl: base.logoUrl,
      coverImageUrl: base.coverImageUrl,
      description: base.description,
      ratingAverage: base.ratingAverage,
      ratingCount: base.ratingCount,
      distanceKm: base.distanceKm,
      status: base.status,
      address: base.address,
      location: base.location,
      operatingHours: base.operatingHours,
      menu: menuRaw is List
          ? menuRaw.whereType<Map<String, dynamic>>().map(FoodMenuItem.fromJson).toList()
          : const [],
    );
  }
}

class FoodMenuItem {
  const FoodMenuItem({
    required this.id,
    required this.partnerId,
    required this.nameVi,
    required this.description,
    required this.imageUrls,
    required this.price,
    required this.currency,
    required this.nutrition,
    required this.category,
    required this.dietaryTags,
    required this.spiceLevel,
    required this.availability,
    required this.ratingAverage,
    required this.ratingCount,
    required this.prepTimeMinutes,
  });

  final String id;
  final String partnerId;
  final String nameVi;
  final String description;
  final List<String> imageUrls;
  final double price;
  final String currency;
  final NutritionSnapshot nutrition;
  final String category;
  final List<String> dietaryTags;
  final String spiceLevel;
  final String availability;
  final double ratingAverage;
  final int ratingCount;
  final int prepTimeMinutes;

  factory FoodMenuItem.fromJson(Map<String, dynamic> json) {
    final tags = json['dietaryTags'];
    final images = json['imageUrls'];
    return FoodMenuItem(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      nameVi: json['nameVi']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrls: images is List ? images.map((e) => e.toString()).toList() : const [],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      nutrition: NutritionSnapshot.fromJson(json['nutrition'] as Map<String, dynamic>?),
      category: json['category']?.toString() ?? '',
      dietaryTags: tags is List ? tags.map((e) => e.toString()).toList() : const [],
      spiceLevel: json['spiceLevel']?.toString() ?? 'Mild',
      availability: json['availability']?.toString() ?? 'Available',
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt() ?? 15,
    );
  }
}

class AffiliateProduct {
  const AffiliateProduct({
    required this.id,
    required this.brandName,
    required this.nameVi,
    required this.description,
    required this.imageUrls,
    required this.price,
    required this.currency,
    required this.affiliateUrl,
    this.nutrition,
    required this.ratingAverage,
    required this.ratingCount,
  });

  final String id;
  final String brandName;
  final String nameVi;
  final String description;
  final List<String> imageUrls;
  final double price;
  final String currency;
  final String affiliateUrl;
  final NutritionSnapshot? nutrition;
  final double ratingAverage;
  final int ratingCount;

  factory AffiliateProduct.fromJson(Map<String, dynamic> json) {
    final images = json['imageUrls'];
    return AffiliateProduct(
      id: json['id']?.toString() ?? '',
      brandName: json['brandName']?.toString() ?? '',
      nameVi: json['nameVi']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrls: images is List ? images.map((e) => e.toString()).toList() : const [],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      affiliateUrl: json['affiliateUrl']?.toString() ?? '',
      nutrition: json['nutrition'] != null
          ? NutritionSnapshot.fromJson(json['nutrition'] as Map<String, dynamic>)
          : null,
      ratingAverage: (json['ratingAverage'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.comment,
    required this.isVerifiedPurchase,
    required this.authorName,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final bool isVerifiedPurchase;
  final String authorName;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> json) {
    final author = json['authorSnapshot'] as Map<String, dynamic>?;
    return Review(
      id: json['id']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: json['comment']?.toString(),
      isVerifiedPurchase: json['isVerifiedPurchase'] == true,
      authorName: author?['fullName']?.toString() ?? 'SYNC User',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class CartLine {
  const CartLine({
    required this.foodMenuItemId,
    required this.partnerId,
    required this.partnerName,
    required this.name,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  final String foodMenuItemId;
  final String partnerId;
  final String partnerName;
  final String name;
  final String? imageUrl;
  final double unitPrice;
  final int quantity;
  final String? notes;

  double get subtotal => unitPrice * quantity;

  CartLine copyWith({int? quantity, String? notes}) => CartLine(
        foodMenuItemId: foodMenuItemId,
        partnerId: partnerId,
        partnerName: partnerName,
        name: name,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        notes: notes ?? this.notes,
      );
}
