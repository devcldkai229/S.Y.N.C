import 'package:dio/dio.dart';
import 'package:sync_app/core/models/api_models.dart';
import 'package:sync_app/core/network/api_paths.dart';
import 'package:sync_app/features/subscription/models/subscription_models.dart';

class SubscriptionApiService {
  SubscriptionApiService(this._dio);

  final Dio _dio;

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.subscriptionPlans);
    final json = response.data ?? {};
    if (json['success'] != true) {
      throw Exception((json['message'] ?? 'Failed to load plans.').toString());
    }
    final raw = json['data'];
    return (raw as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(SubscriptionPlan.fromJson)
        .toList();
  }

  Future<ActiveSubscription?> getActiveSubscription() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myActiveSubscription);
      final envelope = ApiEnvelope.fromJson(
        response.data ?? {},
        ActiveSubscription.fromJson,
      );
      return envelope.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<PaymentLink> createPaymentLink(String planId, {bool yearly = false, String? couponCode}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.payosCreateLink,
      data: {
        'planId': planId,
        'billingCycle': yearly ? 1 : 0,
        if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
      },
    );
    final envelope = ApiEnvelope.fromJson(
      response.data ?? {},
      PaymentLink.fromJson,
    );
    if (envelope.data == null) {
      throw Exception(
          envelope.message.isEmpty ? 'Failed to create payment link.' : envelope.message);
    }
    return envelope.data!;
  }

  Future<TransactionStatus?> getTransactionStatus(int orderCode) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.transactionByOrderCode(orderCode),
      );
      final envelope = ApiEnvelope.fromJson(
        response.data ?? {},
        TransactionStatus.fromJson,
      );
      return envelope.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> cancelSubscription({String? reason}) async {
    await _dio.post<void>(
      ApiPaths.cancelMySubscription,
      data: {'cancellationReason': reason},
    );
  }
}
