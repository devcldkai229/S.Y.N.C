class SubscriptionPlan {
  SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.currency,
    required this.features,
    required this.aiUsageLimitPerMonth,
    required this.premiumWorkoutAccess,
    required this.premiumMarketplaceAccess,
    required this.priorityAiResponses,
    required this.isActive,
    this.googlePlayProductId,
  });

  final String id;
  final String name;
  final String? description;
  final double monthlyPrice;
  final double yearlyPrice;
  final String currency;
  final List<String> features;
  final int aiUsageLimitPerMonth;
  final bool premiumWorkoutAccess;
  final bool premiumMarketplaceAccess;
  final bool priorityAiResponses;
  final bool isActive;
  final String? googlePlayProductId;

  bool get isFree => monthlyPrice <= 0;

  /// Play Console subscription product id (fallback for Premium monthly seed).
  String get playProductId =>
      (googlePlayProductId != null && googlePlayProductId!.isNotEmpty)
          ? googlePlayProductId!
          : 'sync_premium_monthly';

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      description: json['description']?.toString(),
      monthlyPrice: _toDouble(json['monthlyPrice']) ?? 0,
      yearlyPrice: _toDouble(json['yearlyPrice']) ?? 0,
      currency: (json['currency'] ?? 'VND').toString(),
      features: (json['features'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      aiUsageLimitPerMonth: (json['aiUsageLimitPerMonth'] ?? 0) as int,
      premiumWorkoutAccess: json['premiumWorkoutAccess'] == true,
      premiumMarketplaceAccess: json['premiumMarketplaceAccess'] == true,
      priorityAiResponses: json['priorityAiResponses'] == true,
      isActive: json['isActive'] == true,
      googlePlayProductId: json['googlePlayProductId']?.toString(),
    );
  }
}

class ActiveSubscription {
  ActiveSubscription({
    required this.id,
    required this.planName,
    required this.subscriptionPlanName,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.expiredAt,
  });

  final String id;
  final String planName;
  final String subscriptionPlanName;
  final String status;
  final DateTime startedAt;
  final String? expiresAt;
  final DateTime? expiredAt;

  /// .NET may serialize enum as name ("Active") or number (Active=1).
  bool get isActive {
    final s = status.trim().toLowerCase();
    final notExpired =
        expiredAt == null || expiredAt!.isAfter(DateTime.now().toUtc());

    // Trial=0, Active=1 — still entitled while not past expiry.
    if (s == 'active' || s == '1' || s == 'trial' || s == '0') {
      return notExpired;
    }
    // Cancelled=3 but still within paid period.
    if (s == 'cancelled' || s == '3') {
      return expiredAt != null && expiredAt!.isAfter(DateTime.now().toUtc());
    }
    return false;
  }

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? {};
    final planNameVal =
        (plan['name'] ?? json['planName'] ?? json['subscriptionPlanName'] ?? '')
            .toString();
    final startedAtVal =
        DateTime.tryParse(json['startedAt']?.toString() ?? '') ?? DateTime.now();

    DateTime? expiredAtVal;
    if (json['expiredAt'] != null) {
      expiredAtVal = DateTime.tryParse(json['expiredAt'].toString());
    } else if (json['expiresAt'] != null) {
      expiredAtVal = DateTime.tryParse(json['expiresAt'].toString());
    }

    return ActiveSubscription(
      id: json['id']?.toString() ?? '',
      planName: planNameVal,
      subscriptionPlanName: planNameVal,
      status: (json['status'] ?? '').toString(),
      startedAt: startedAtVal,
      expiresAt: json['expiresAt']?.toString() ?? json['expiredAt']?.toString(),
      expiredAt: expiredAtVal,
    );
  }
}

/// True when IAM / profile reports a paid digital tier (Premium / Ultra).
bool isPaidSubscriptionTier(String? tier) {
  final t = (tier ?? '').trim().toLowerCase();
  return t.contains('premium') || t.contains('ultra');
}

class PaymentLink {
  PaymentLink({
    required this.transactionId,
    required this.orderCode,
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.currency,
  });

  final String transactionId;
  final int orderCode;
  final String checkoutUrl;
  final String qrCode;
  final int amount;
  final String currency;

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    return PaymentLink(
      transactionId: (json['transactionId'] ?? json['transactionId'] ?? '').toString(),
      orderCode: (json['orderCode'] ?? 0) as int,
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      amount: (json['amount'] ?? 0) as int,
      currency: (json['currency'] ?? 'VND').toString(),
    );
  }
}

class TransactionStatus {
  const TransactionStatus({
    required this.id,
    required this.orderCode,
    required this.status,
  });

  final String id;
  final int orderCode;
  final String status;

  factory TransactionStatus.fromJson(Map<String, dynamic> json) => TransactionStatus(
        id: json['id'] as String? ?? '',
        orderCode: json['orderCode'] as int? ?? 0,
        status: json['status'] as String? ?? '',
      );
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
