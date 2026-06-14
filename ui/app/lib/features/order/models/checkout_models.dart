import 'package:sync_app/features/order/models/order_models.dart';

class WalletBalance {
  const WalletBalance({
    required this.availableBalance,
    required this.currency,
    this.coinBalance,
    this.vndPerCoin = 100,
  });

  final double availableBalance;
  final String currency;
  final double? coinBalance;
  final double vndPerCoin;

  double get coins => coinBalance ?? availableBalance;

  double coinsRequiredForVnd(double amountVnd) => amountVnd / vndPerCoin;

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
        currency: json['currency']?.toString() ?? 'COIN',
        coinBalance: (json['coinBalance'] as num?)?.toDouble(),
        vndPerCoin: (json['vndPerCoin'] as num?)?.toDouble() ?? 100,
      );
}

enum CheckoutPaymentMethod { wallet, vietqr, cod }

class VoucherItem {
  const VoucherItem({
    required this.code,
    required this.title,
    this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    this.maxDiscount,
    required this.validUntil,
    required this.estimatedDiscount,
    required this.eligible,
    this.ineligibleReason,
    required this.campaignId,
  });

  final String code;
  final String title;
  final String? description;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscount;
  final DateTime validUntil;
  final double estimatedDiscount;
  final bool eligible;
  final String? ineligibleReason;
  final String campaignId;

  factory VoucherItem.fromJson(Map<String, dynamic> json) => VoucherItem(
        code: json['code']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        discountType: json['discountType']?.toString() ?? '',
        discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0,
        minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0,
        maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
        validUntil: DateTime.tryParse(json['validUntil']?.toString() ?? '') ?? DateTime.now(),
        estimatedDiscount: (json['estimatedDiscount'] as num?)?.toDouble() ?? 0,
        eligible: json['eligible'] == true,
        ineligibleReason: json['ineligibleReason']?.toString(),
        campaignId: json['campaignId']?.toString() ?? '',
      );
}

class VoucherValidation {
  const VoucherValidation({
    required this.valid,
    required this.discountAmount,
    this.message,
    this.code,
  });

  final bool valid;
  final double discountAmount;
  final String? message;
  final String? code;

  factory VoucherValidation.fromJson(Map<String, dynamic> json) => VoucherValidation(
        valid: json['valid'] == true,
        discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        message: json['message']?.toString(),
      );
}

class PlaceOrderResult {
  const PlaceOrderResult({
    required this.order,
    this.payUrl,
    this.deeplink,
    this.checkoutUrl,
    this.qrCode,
    this.payOsOrderCode,
    required this.requiresExternalPayment,
  });

  final OrderSummary order;
  final String? payUrl;
  final String? deeplink;
  final String? checkoutUrl;
  final String? qrCode;
  final int? payOsOrderCode;
  final bool requiresExternalPayment;
}
