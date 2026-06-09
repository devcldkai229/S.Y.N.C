class SubscriptionPlan {
  final String id;
  final String name;
  final String? description;
  final double monthlyPrice;
  final String currency;
  final List<String> features;
  final int aiUsageLimitPerMonth;
  final bool premiumWorkoutAccess;
  final bool priorityAiResponses;
  final bool isActive;

  bool get isFree => monthlyPrice <= 0;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    this.description,
    required this.monthlyPrice,
    required this.currency,
    required this.features,
    required this.aiUsageLimitPerMonth,
    required this.premiumWorkoutAccess,
    required this.priorityAiResponses,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) => SubscriptionPlan(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        monthlyPrice: (json['monthlyPrice'] as num? ?? 0).toDouble(),
        currency: json['currency'] as String? ?? 'VND',
        features: (json['features'] as List<dynamic>?)?.cast<String>() ?? [],
        aiUsageLimitPerMonth: json['aiUsageLimitPerMonth'] as int? ?? 0,
        premiumWorkoutAccess: json['premiumWorkoutAccess'] as bool? ?? false,
        priorityAiResponses: json['priorityAiResponses'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? false,
      );
}

class PaymentLink {
  final String transactionId;
  final int orderCode;
  final String checkoutUrl;
  final String qrCode;
  final int amount;
  final String currency;

  const PaymentLink({
    required this.transactionId,
    required this.orderCode,
    required this.checkoutUrl,
    required this.qrCode,
    required this.amount,
    required this.currency,
  });

  factory PaymentLink.fromJson(Map<String, dynamic> json) => PaymentLink(
        transactionId: json['transactionId'] as String? ?? '',
        orderCode: json['orderCode'] as int? ?? 0,
        checkoutUrl: json['checkoutUrl'] as String? ?? '',
        qrCode: json['qrCode'] as String? ?? '',
        amount: json['amount'] as int? ?? 0,
        currency: json['currency'] as String? ?? 'VND',
      );
}

class ActiveSubscription {
  final String id;
  final String subscriptionPlanName;
  final String status;
  final DateTime startedAt;
  final DateTime? expiredAt;

  const ActiveSubscription({
    required this.id,
    required this.subscriptionPlanName,
    required this.status,
    required this.startedAt,
    this.expiredAt,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) => ActiveSubscription(
        id: json['id'] as String? ?? '',
        subscriptionPlanName: json['subscriptionPlanName'] as String? ?? '',
        status: json['status'] as String? ?? '',
        startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now(),
        expiredAt: json['expiredAt'] != null
            ? DateTime.tryParse(json['expiredAt'] as String)
            : null,
      );
}

class TransactionStatus {
  final String id;
  final int orderCode;
  final String status;

  const TransactionStatus({
    required this.id,
    required this.orderCode,
    required this.status,
  });

  factory TransactionStatus.fromJson(Map<String, dynamic> json) => TransactionStatus(
        id: json['id'] as String? ?? '',
        orderCode: json['orderCode'] as int? ?? 0,
        status: json['status'] as String? ?? '',
      );
}
