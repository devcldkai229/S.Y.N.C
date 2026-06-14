import 'package:dio/dio.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/order/models/checkout_models.dart';

class PaymentRemoteDataSource {
  PaymentRemoteDataSource(this._dio);

  final Dio _dio;

  Future<WalletBalance> getWalletBalance() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.paymentWalletMe);
    return _parseEnvelope(response.data, WalletBalance.fromJson);
  }

  Future<List<VoucherItem>> getAvailableVouchers({
    required double orderAmount,
    String? partnerId,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.paymentVouchersAvailable,
      queryParameters: {
        'orderAmount': orderAmount,
        if (partnerId != null) 'partnerId': partnerId,
      },
    );
    final json = response.data;
    if (json == null || json['success'] != true) return [];
    final data = json['data'];
    if (data is! List) return [];
    return data.whereType<Map<String, dynamic>>().map(VoucherItem.fromJson).toList();
  }

  Future<VoucherValidation> validateVoucher({
    required String code,
    required double orderAmount,
    String? partnerId,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.paymentVouchersValidate,
      data: {
        'code': code,
        'orderAmount': orderAmount,
        if (partnerId != null) 'partnerId': partnerId,
      },
    );
    final result = _parseEnvelope(response.data, VoucherValidation.fromJson);
    return VoucherValidation(
      valid: result.valid,
      discountAmount: result.discountAmount,
      message: result.message,
      code: code.trim().toUpperCase(),
    );
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
}
