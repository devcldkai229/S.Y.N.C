import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sync_app/features/subscription/services/subscription_api_service.dart';

/// Google Play Billing helper for Premium subscriptions.
///
/// Flow: query product → buy → listen purchaseStream → POST verify → completePurchase.
class GooglePlayBillingService {
  GooglePlayBillingService(this._api);

  final SubscriptionApiService _api;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<void>? _pendingBuy;
  String? _pendingPlanId;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> isAvailable() async {
    if (!isSupported) return false;
    return _iap.isAvailable();
  }

  void ensureListening() {
    _purchaseSub ??= _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        _failPending(e);
      },
    );
  }

  Future<void> purchaseSubscription({
    required String productId,
    required String planId,
  }) async {
    if (!isSupported) {
      throw Exception('Google Play Billing chỉ khả dụng trên Android.');
    }
    ensureListening();

    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('Cửa hàng Google Play không khả dụng trên thiết bị này.');
    }

    final response = await _iap.queryProductDetails({productId});
    if (response.error != null) {
      throw Exception('Không tải được sản phẩm Play: ${response.error!.message}');
    }
    if (response.productDetails.isEmpty) {
      throw Exception(
        'Không tìm thấy sản phẩm "$productId" trên Play Console. '
        'Hãy tạo subscription product và publish lên Internal testing.',
      );
    }

    final product = response.productDetails.first;
    _pendingPlanId = planId;
    _pendingBuy = Completer<void>();

    final param = PurchaseParam(productDetails: product);
    final started = await _iap.buyNonConsumable(purchaseParam: param);
    if (!started) {
      _pendingBuy = null;
      throw Exception('Không thể mở hộp thoại thanh toán Google Play.');
    }

    return _pendingBuy!.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () {
        _pendingBuy = null;
        throw Exception('Hết thời gian chờ thanh toán Google Play.');
      },
    );
  }

  /// Restore / re-verify existing Play purchases (e.g. after reinstall).
  Future<void> restoreAndVerify() async {
    if (!isSupported) return;
    ensureListening();
    await _iap.restorePurchases();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        continue;
      }

      if (purchase.status == PurchaseStatus.error) {
        _failPending(
          Exception(purchase.error?.message ?? 'Google Play purchase failed.'),
        );
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.canceled) {
        _failPending(Exception('Bạn đã huỷ thanh toán Google Play.'));
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }
        continue;
      }

      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final token = purchase.verificationData.serverVerificationData;
        final productId = purchase.productID;
        if (token.isEmpty) {
          _failPending(Exception('Thiếu purchaseToken từ Google Play.'));
          continue;
        }

        try {
          await _api.verifyGooglePlayPurchase(
            productId: productId,
            purchaseToken: token,
            planId: _pendingPlanId,
          );
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          _completePending();
        } catch (e) {
          _failPending(e);
        }
      }
    }
  }

  void _completePending() {
    final c = _pendingBuy;
    _pendingBuy = null;
    _pendingPlanId = null;
    if (c != null && !c.isCompleted) c.complete();
  }

  void _failPending(Object error) {
    final c = _pendingBuy;
    _pendingBuy = null;
    _pendingPlanId = null;
    if (c != null && !c.isCompleted) c.completeError(error);
  }

  void dispose() {
    _purchaseSub?.cancel();
    _purchaseSub = null;
  }
}
