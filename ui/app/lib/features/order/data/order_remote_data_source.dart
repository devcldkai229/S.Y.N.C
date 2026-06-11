import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/order/models/order_models.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource(this._dio);

  final Dio _dio;

  Future<OrderSummary> placeOrder(Map<String, dynamic> body) async {
    final response = await _dio.post<Map<String, dynamic>>(ApiPaths.orderOrders, data: body);
    return _parseEnvelope(response.data, OrderSummary.fromJson);
  }

  Future<List<OrderSummary>> listOrders({String? status, int page = 1}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.orderOrders,
      queryParameters: {
        if (status != null) 'status': status,
        'pageNumber': page,
        'pageSize': 20,
      },
    );
    return _parsePaged(response.data, OrderSummary.fromJson);
  }

  Future<OrderSummary> getOrder(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.orderById(id));
    return _parseEnvelope(response.data, OrderSummary.fromJson);
  }

  Future<DeliveryTracking?> getTracking(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.orderTracking(id));
    final json = response.data;
    if (json == null || json['success'] != true) return null;
    final data = json['data'];
    if (data == null) return null;
    if (data is! Map<String, dynamic>) return null;
    return DeliveryTracking.fromJson(data);
  }

  Future<OrderSummary> cancelOrder(String id, {String? reason}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.orderCancel(id),
      data: {'reason': reason},
    );
    return _parseEnvelope(response.data, OrderSummary.fromJson);
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
}
