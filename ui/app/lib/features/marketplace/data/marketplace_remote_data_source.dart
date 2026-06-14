import 'dart:math';

import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/marketplace/models/marketplace_models.dart';

class MarketplaceRemoteDataSource {
  MarketplaceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Partner>> searchPartners({
    String? query,
    double? lat,
    double? lng,
    double radiusKm = 10,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplacePartners,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
        if (lat != null && lng != null) 'radiusKm': radiusKm,
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    return _parsePaged(response.data, Partner.fromJson);
  }

  Future<PartnerDetail> getPartner(String id, {double? lat, double? lng}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplacePartnerById(id),
      queryParameters: {
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
      },
    );
    return _parseEnvelope(response.data, PartnerDetail.fromJson);
  }

  Future<List<FoodMenuItem>> getFoodSuggestions({
    int count = 10,
    double? lat,
    double? lng,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.marketplaceFoodSuggestions,
        queryParameters: {
          'count': count,
          if (lat != null) 'latitude': lat,
          if (lng != null) 'longitude': lng,
          'radiusKm': 15,
        },
      );
      return _parseList(response.data, FoodMenuItem.fromJson);
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) rethrow;
      return _randomFoodFromSearch(count: count, lat: lat, lng: lng);
    }
  }

  Future<List<FoodMenuItem>> _randomFoodFromSearch({
    required int count,
    double? lat,
    double? lng,
  }) async {
    final items = await searchFoodMenu(
      lat: lat,
      lng: lng,
      pageSize: 60,
    );
    if (items.isEmpty) return items;
    final pool = List<FoodMenuItem>.from(items)..shuffle(Random());
    return pool.take(count).toList();
  }

  Future<List<FoodMenuItem>> searchFoodMenu({
    String? query,
    String? category,
    List<String>? dietaryTags,
    double? lat,
    double? lng,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplaceFoodMenu,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'query': query,
        if (category != null) 'category': category,
        if (dietaryTags != null && dietaryTags.isNotEmpty) 'dietaryTags': dietaryTags,
        if (lat != null) 'latitude': lat,
        if (lng != null) 'longitude': lng,
        'radiusKm': 15,
        'pageNumber': page,
        'pageSize': pageSize,
      },
    );
    return _parsePaged(response.data, FoodMenuItem.fromJson);
  }

  Future<FoodMenuItem> getFoodMenuItem(String id) async {
    final response =
        await _dio.get<Map<String, dynamic>>(ApiPaths.marketplaceFoodMenuById(id));
    return _parseEnvelope(response.data, FoodMenuItem.fromJson);
  }

  Future<List<AffiliateProduct>> searchAffiliate({int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplaceAffiliateProducts,
      queryParameters: {'pageNumber': page, 'pageSize': 20},
    );
    return _parsePaged(response.data, AffiliateProduct.fromJson);
  }

  Future<AffiliateProduct> getAffiliateProduct(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplaceAffiliateProductById(id),
    );
    return _parseEnvelope(response.data, AffiliateProduct.fromJson);
  }

  Future<String> trackAffiliateClick(String productId, {String source = 'browse'}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.marketplaceAffiliateClick(productId),
      queryParameters: {'source': source},
    );
    final data = _parseEnvelopeMap(response.data);
    return data['redirectUrl']?.toString() ?? '';
  }

  Future<List<Review>> listReviews({
    required String targetType,
    required String targetId,
    int page = 1,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.marketplaceReviews,
      queryParameters: {
        'targetType': targetType,
        'targetId': targetId,
        'pageNumber': page,
        'pageSize': 20,
      },
    );
    return _parsePaged(response.data, Review.fromJson);
  }

  Future<Review> createReview(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.marketplaceReviews,
      data: body,
    );
    return _parseEnvelope(response.data, Review.fromJson);
  }

  T _parseEnvelope<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid data');
    return fromJson(data);
  }

  Map<String, dynamic> _parseEnvelopeMap(Map<String, dynamic>? json) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) return {};
    return data;
  }

  List<T> _parsePaged<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  List<T> _parseList<T>(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
