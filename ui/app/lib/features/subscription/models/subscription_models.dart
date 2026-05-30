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

  bool get isFree => monthlyPrice == 0;

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
    );
  }
}

class ActiveSubscription {
  ActiveSubscription({
    required this.id,
    required this.planName,
    required this.status,
    this.expiresAt,
  });

  final String id;
  final String planName;
  final String status;
  final String? expiresAt;

  bool get isActive => status.toLowerCase() == 'active';

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'] as Map<String, dynamic>? ?? {};
    return ActiveSubscription(
      id: json['id']?.toString() ?? '',
      planName: (plan['name'] ?? json['planName'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      expiresAt: json['expiresAt']?.toString(),
    );
  }
}

class PaymentLink {
  PaymentLink({
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.orderCode,
  });

  final String checkoutUrl;
  final String qrCode;
  final int amount;
  final int orderCode;

  factory PaymentLink.fromJson(Map<String, dynamic> json) {
    return PaymentLink(
      checkoutUrl: (json['checkoutUrl'] ?? '').toString(),
      qrCode: (json['qrCode'] ?? '').toString(),
      amount: (json['amount'] ?? 0) as int,
      orderCode: (json['orderCode'] ?? 0) as int,
    );
  }
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
