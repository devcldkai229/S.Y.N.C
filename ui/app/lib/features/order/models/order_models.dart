class OrderItem {
  const OrderItem({
    required this.id,
    required this.foodMenuItemId,
    required this.nameSnapshot,
    this.imageUrlSnapshot,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.notes,
  });

  final String id;
  final String foodMenuItemId;
  final String nameSnapshot;
  final String? imageUrlSnapshot;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final String? notes;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id']?.toString() ?? '',
        foodMenuItemId: json['foodMenuItemId']?.toString() ?? '',
        nameSnapshot: json['nameSnapshot']?.toString() ?? '',
        imageUrlSnapshot: json['imageUrlSnapshot']?.toString(),
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        notes: json['notes']?.toString(),
      );
}

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.partnerId,
    required this.orderCode,
    required this.status,
    required this.subtotalAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.totalAmount,
    required this.currency,
    required this.placedAt,
    this.completedAt,
    this.deliveryAddress,
    this.deliveryLat,
    this.deliveryLng,
    this.recipientName,
    this.recipientPhone,
    required this.items,
    this.tracking,
  });

  final String id;
  final String partnerId;
  final String orderCode;
  final String status;
  final double subtotalAmount;
  final double deliveryFee;
  final double discountAmount;
  final double totalAmount;
  final String currency;
  final DateTime placedAt;
  final DateTime? completedAt;
  final String? deliveryAddress;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? recipientName;
  final String? recipientPhone;
  final List<OrderItem> items;
  final DeliveryTracking? tracking;

  bool get isActive => !const {'Completed', 'Cancelled', 'Refunded'}.contains(status);

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    return OrderSummary(
      id: json['id']?.toString() ?? '',
      partnerId: json['partnerId']?.toString() ?? '',
      orderCode: json['orderCode']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      subtotalAmount: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
      currency: json['currency']?.toString() ?? 'VND',
      placedAt: DateTime.tryParse(json['placedAt']?.toString() ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
      deliveryAddress: json['deliveryAddress']?.toString(),
      deliveryLat: (json['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (json['deliveryLng'] as num?)?.toDouble(),
      recipientName: json['recipientName']?.toString(),
      recipientPhone: json['recipientPhone']?.toString(),
      items: itemsRaw is List
          ? itemsRaw.whereType<Map<String, dynamic>>().map(OrderItem.fromJson).toList()
          : const [],
      tracking: json['tracking'] != null
          ? DeliveryTracking.fromJson(json['tracking'] as Map<String, dynamic>)
          : null,
    );
  }
}

class DeliveryTracking {
  const DeliveryTracking({
    required this.orderId,
    required this.status,
    this.shipperName,
    this.shipperPhone,
    this.shipperPlateNumber,
    this.lastKnownLat,
    this.lastKnownLng,
    this.lastLocationUpdatedAt,
    this.estimatedArrivalAt,
  });

  final String orderId;
  final String status;
  final String? shipperName;
  final String? shipperPhone;
  final String? shipperPlateNumber;
  final double? lastKnownLat;
  final double? lastKnownLng;
  final DateTime? lastLocationUpdatedAt;
  final DateTime? estimatedArrivalAt;

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) => DeliveryTracking(
        orderId: json['orderId']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Pending',
        shipperName: json['shipperName']?.toString(),
        shipperPhone: json['shipperPhone']?.toString(),
        shipperPlateNumber: json['shipperPlateNumber']?.toString(),
        lastKnownLat: (json['lastKnownLat'] as num?)?.toDouble(),
        lastKnownLng: (json['lastKnownLng'] as num?)?.toDouble(),
        lastLocationUpdatedAt: json['lastLocationUpdatedAt'] != null
            ? DateTime.tryParse(json['lastLocationUpdatedAt'].toString())
            : null,
        estimatedArrivalAt: json['estimatedArrivalAt'] != null
            ? DateTime.tryParse(json['estimatedArrivalAt'].toString())
            : null,
      );
}

class TrackingLocationUpdate {
  const TrackingLocationUpdate({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String orderId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  factory TrackingLocationUpdate.fromJson(Map<String, dynamic> json) => TrackingLocationUpdate(
        orderId: json['orderId']?.toString() ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
