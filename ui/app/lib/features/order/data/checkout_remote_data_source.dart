import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';

class AddressSuggestion {
  const AddressSuggestion({
    required this.label,
    required this.lat,
    required this.lng,
    this.placeId,
  });

  final String label;
  final double lat;
  final double lng;
  final String? placeId;

  factory AddressSuggestion.fromJson(Map<String, dynamic> json) => AddressSuggestion(
        label: json['label']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        placeId: json['placeId']?.toString(),
      );
}

class ReverseGeocodeResult {
  const ReverseGeocodeResult({
    required this.label,
    required this.lat,
    required this.lng,
    this.addressLine,
    this.ward,
    this.district,
    this.city,
  });

  final String label;
  final double lat;
  final double lng;
  final String? addressLine;
  final String? ward;
  final String? district;
  final String? city;

  factory ReverseGeocodeResult.fromJson(Map<String, dynamic> json) => ReverseGeocodeResult(
        label: json['label']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
        addressLine: json['addressLine']?.toString(),
        ward: json['ward']?.toString(),
        district: json['district']?.toString(),
        city: json['city']?.toString(),
      );
}

class SavedDeliveryAddress {
  const SavedDeliveryAddress({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  factory SavedDeliveryAddress.fromJson(Map<String, dynamic> json) => SavedDeliveryAddress(
        label: json['label']?.toString() ?? '',
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lng: (json['lng'] as num?)?.toDouble() ?? 0,
      );
}

class RemoteCartItem {
  const RemoteCartItem({
    required this.foodMenuItemId,
    required this.nameSnapshot,
    this.imageUrlSnapshot,
    required this.unitPrice,
    required this.quantity,
    this.notes,
  });

  final String foodMenuItemId;
  final String nameSnapshot;
  final String? imageUrlSnapshot;
  final double unitPrice;
  final int quantity;
  final String? notes;

  factory RemoteCartItem.fromJson(Map<String, dynamic> json) => RemoteCartItem(
        foodMenuItemId: json['foodMenuItemId']?.toString() ?? '',
        nameSnapshot: json['nameSnapshot']?.toString() ?? '',
        imageUrlSnapshot: json['imageUrlSnapshot']?.toString(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        notes: json['notes']?.toString(),
      );
}

class CheckoutFees {
  const CheckoutFees({
    required this.defaultDeliveryFee,
    this.currency = 'VND',
  });

  final double defaultDeliveryFee;
  final String currency;

  factory CheckoutFees.fromJson(Map<String, dynamic> json) => CheckoutFees(
        defaultDeliveryFee: (json['defaultDeliveryFee'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? 'VND',
      );
}

class RemoteCart {
  const RemoteCart({
    this.partnerId,
    this.partnerName,
    this.items = const [],
    this.subtotal = 0,
    this.deliveryFee = 0,
  });

  final String? partnerId;
  final String? partnerName;
  final List<RemoteCartItem> items;
  final double subtotal;
  final double deliveryFee;

  int get itemCount => items.fold(0, (s, i) => s + i.quantity);

  factory RemoteCart.fromJson(Map<String, dynamic> json) => RemoteCart(
        partnerId: json['partnerId']?.toString(),
        partnerName: json['partnerName']?.toString(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
        items: (json['items'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(RemoteCartItem.fromJson)
            .toList(),
      );
}

class CartPartnerConflict implements Exception {
  CartPartnerConflict(this.message);
  final String message;
}

class CheckoutRemoteDataSource {
  CheckoutRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<AddressSuggestion>> searchAddress(
    String query, {
    double? lat,
    double? lng,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.checkoutAddressSearch,
      queryParameters: {
        'q': query,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
    );
    return _parseList(response.data, AddressSuggestion.fromJson);
  }

  Future<ReverseGeocodeResult> reverseGeocode(double lat, double lng) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.checkoutAddressReverse,
      queryParameters: {'lat': lat, 'lng': lng},
    );
    return _parseData(response.data, ReverseGeocodeResult.fromJson);
  }

  Future<SavedDeliveryAddress?> getCurrentAddress() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.checkoutAddressCurrent);
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return null;
    return SavedDeliveryAddress.fromJson(data);
  }

  Future<void> saveCurrentAddress({
    required String label,
    required double lat,
    required double lng,
  }) async {
    await _dio.post<void>(
      ApiPaths.checkoutAddressCurrent,
      data: {'label': label, 'lat': lat, 'lng': lng},
    );
  }

  Future<CheckoutFees> getCheckoutFees() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.checkoutFees);
    return _parseData(response.data, CheckoutFees.fromJson);
  }

  Future<RemoteCart> getCart() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.checkoutCart);
    final data = response.data?['data'];
    if (data is! Map<String, dynamic>) return const RemoteCart();
    return RemoteCart.fromJson(data);
  }

  Future<RemoteCart> addCartItem({
    required String partnerId,
    required String foodMenuItemId,
    int quantity = 1,
    String? notes,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.checkoutCartItems,
        data: {
          'partnerId': partnerId,
          'foodMenuItemId': foodMenuItemId,
          'quantity': quantity,
          if (notes != null) 'notes': notes,
        },
      );
      return _parseData(response.data, RemoteCart.fromJson);
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final errors = e.response?.data?['errors'];
        final requiresClear = errors is Map && errors['requiresClear'] == true;
        if (requiresClear) {
          throw CartPartnerConflict(
            e.response?.data?['message']?.toString() ?? 'Cart conflict',
          );
        }
      }
      rethrow;
    }
  }

  Future<RemoteCart> updateCartItemQuantity(String foodMenuItemId, int quantity) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      ApiPaths.checkoutCartItem(foodMenuItemId),
      data: {'quantity': quantity},
    );
    return _parseData(response.data, RemoteCart.fromJson);
  }

  Future<void> clearCart() async {
    await _dio.delete<void>(ApiPaths.checkoutCart);
  }

  T _parseData<T>(Map<String, dynamic>? json, T Function(Map<String, dynamic>) fromJson) {
    if (json == null || json['success'] != true) {
      throw Exception(json?['message']?.toString() ?? 'Request failed');
    }
    final data = json['data'];
    if (data is! Map<String, dynamic>) throw Exception('Invalid response data');
    return fromJson(data);
  }

  List<T> _parseList<T>(Map<String, dynamic>? json, T Function(Map<String, dynamic>) fromJson) {
    if (json == null || json['success'] != true) return [];
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }
}
