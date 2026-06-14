import 'package:sync_app/core/utils/app_location_resolver.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/order/config/mock_tracking_config.dart';
import 'package:sync_app/features/order/mock/order_demo_data.dart';
import 'package:sync_app/features/order/models/order_models.dart';

/// Demo order list — swap for [OrderRemoteDataSource] when API is ready.
class OrderDemoRepository {
  OrderSummary? _cachedActive;

  Future<({List<OrderListItemVm> active, List<OrderListItemVm> history})> loadOrders() async {
    final drop = await _resolveDropoff();
    final active = OrderListItemVm(
      order: OrderDemoData.activeOrder(
        deliveryLat: drop.lat,
        deliveryLng: drop.lng,
        deliveryAddress: drop.address,
      ),
      partnerName: MockTrackingConfig.pickupLabel,
      etaMinutes: 15,
    );
    _cachedActive = active.order;
    return (
      active: [active],
      history: OrderDemoData.historyOrders(),
    );
  }

  OrderSummary? getOrder(String id) {
    if (id == MockTrackingConfig.demoActiveOrderId) return _cachedActive;
    for (final h in OrderDemoData.historyOrders()) {
      if (h.order.id == id) return h.order;
    }
    return null;
  }

  OrderListItemVm? findListItem(String id) {
    if (id == MockTrackingConfig.demoActiveOrderId && _cachedActive != null) {
      return OrderListItemVm(
        order: _cachedActive!,
        partnerName: MockTrackingConfig.pickupLabel,
        etaMinutes: 15,
      );
    }
    for (final h in OrderDemoData.historyOrders()) {
      if (h.order.id == id) return h;
    }
    return null;
  }

  Future<({double lat, double lng, String address})> _resolveDropoff() async {
    final loc = await AppLocationResolver.resolve(requestPermission: true);
    if (loc.lat != null && loc.lng != null) {
      final full = await MarketplaceLocationService.reverseGeocode(loc.lat!, loc.lng!);
      return (
        lat: loc.lat!,
        lng: loc.lng!,
        address: MarketplaceLocationService.shortenAddress(
          full ?? MockTrackingConfig.fallbackDropLabel,
        ),
      );
    }
    return (
      lat: MockTrackingConfig.fallbackDropLat,
      lng: MockTrackingConfig.fallbackDropLng,
      address: MockTrackingConfig.fallbackDropLabel,
    );
  }
}
