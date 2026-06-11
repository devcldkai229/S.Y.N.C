import 'package:sync_app/features/order/config/mock_tracking_config.dart';
import 'package:sync_app/features/order/models/order_models.dart';

class OrderListItemVm {
  const OrderListItemVm({
    required this.order,
    required this.partnerName,
    this.etaMinutes,
  });

  final OrderSummary order;
  final String partnerName;
  final int? etaMinutes;
}

/// Static orders for tracking demo.
abstract final class OrderDemoData {
  static OrderSummary activeOrder({
    double? deliveryLat,
    double? deliveryLng,
    String? deliveryAddress,
  }) =>
      OrderSummary(
        id: MockTrackingConfig.demoActiveOrderId,
        partnerId: 'p-demo-kitchen',
        orderCode: 'SYNC-DEMO-001',
        status: 'Delivering',
        subtotalAmount: 160000,
        deliveryFee: 25000,
        discountAmount: 0,
        totalAmount: 185000,
        currency: 'VND',
        placedAt: DateTime.now().subtract(const Duration(minutes: 8)),
        deliveryAddress: deliveryAddress ?? MockTrackingConfig.fallbackDropLabel,
        deliveryLat: deliveryLat ?? MockTrackingConfig.fallbackDropLat,
        deliveryLng: deliveryLng ?? MockTrackingConfig.fallbackDropLng,
        recipientName: 'Khải',
        recipientPhone: '0900000000',
        items: const [
          OrderItem(
            id: 'oi-1',
            foodMenuItemId: 'f-demo-1',
            nameSnapshot: 'Cơm gà Healthy',
            unitPrice: 80000,
            quantity: 2,
            subtotal: 160000,
          ),
        ],
        tracking: DeliveryTracking(
          orderId: MockTrackingConfig.demoActiveOrderId,
          status: 'Delivering',
          shipperName: MockTrackingConfig.shipperName,
          shipperPhone: MockTrackingConfig.shipperPhone,
          shipperPlateNumber: MockTrackingConfig.shipperPlate,
          estimatedArrivalAt: DateTime.now().add(const Duration(minutes: 15)),
        ),
      );

  static List<OrderListItemVm> historyOrders() => [
        OrderListItemVm(
          order: OrderSummary(
            id: 'demo-history-1',
            partnerId: 'p1',
            orderCode: 'SYNC-DEMO-H01',
            status: 'Completed',
            subtotalAmount: 89000,
            deliveryFee: 15000,
            discountAmount: 0,
            totalAmount: 104000,
            currency: 'VND',
            placedAt: DateTime.now().subtract(const Duration(days: 2)),
            completedAt: DateTime.now().subtract(const Duration(days: 2)).add(const Duration(hours: 1)),
            deliveryAddress: 'Quận 1, TP.HCM',
            items: const [
              OrderItem(
                id: 'h1',
                foodMenuItemId: 'f1',
                nameSnapshot: 'Salad Gà Nướng',
                unitPrice: 89000,
                quantity: 1,
                subtotal: 89000,
              ),
            ],
          ),
          partnerName: 'Green Bowl Kitchen',
        ),
        OrderListItemVm(
          order: OrderSummary(
            id: 'demo-history-2',
            partnerId: 'p2',
            orderCode: 'SYNC-DEMO-H02',
            status: 'Completed',
            subtotalAmount: 150000,
            deliveryFee: 18000,
            discountAmount: 0,
            totalAmount: 168000,
            currency: 'VND',
            placedAt: DateTime.now().subtract(const Duration(days: 5)),
            completedAt: DateTime.now().subtract(const Duration(days: 5)).add(const Duration(hours: 1)),
            deliveryAddress: 'Quận 3, TP.HCM',
            items: const [
              OrderItem(
                id: 'h2',
                foodMenuItemId: 'f2',
                nameSnapshot: 'Bowl Bí Đỏ Hạt Chia',
                unitPrice: 75000,
                quantity: 2,
                subtotal: 150000,
              ),
            ],
          ),
          partnerName: 'Fit Meal Saigon',
        ),
      ];
}
