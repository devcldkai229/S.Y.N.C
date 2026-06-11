import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/services/order_tracking_service.dart';
import 'package:sync_app/features/order/widgets/live_tracking_map.dart';
import 'package:sync_app/features/order/widgets/order_status_stepper.dart';
import 'package:sync_app/features/order/widgets/shipper_card.dart';
import 'package:sync_app/features/order/widgets/status_chip.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _api = getIt<OrderRemoteDataSource>();
  final _trackingService = getIt<OrderTrackingService>();
  OrderSummary? _order;
  LatLng? _shipper;
  StreamSubscription<TrackingLocationUpdate>? _sub;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _connectRealtime();
    _fallbackTimer = Timer.periodic(const Duration(seconds: 20), (_) => _refreshTracking());
  }

  Future<void> _load() async {
    final order = await _api.getOrder(widget.orderId);
    if (!mounted) return;
    setState(() => _order = order);
    _applyTracking(order.tracking);
  }

  Future<void> _refreshTracking() async {
    final t = await _api.getTracking(widget.orderId);
    if (t != null && mounted) _applyTracking(t);
  }

  void _applyTracking(DeliveryTracking? t) {
    if (t?.lastKnownLat != null && t?.lastKnownLng != null) {
      setState(() => _shipper = LatLng(t!.lastKnownLat!, t.lastKnownLng!));
    }
  }

  Future<void> _connectRealtime() async {
    await _trackingService.connect(widget.orderId);
    _sub = _trackingService.locations.listen((u) {
      if (!mounted) return;
      setState(() => _shipper = LatLng(u.latitude, u.longitude));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _fallbackTimer?.cancel();
    _trackingService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dest = order.deliveryLat != null && order.deliveryLng != null
        ? LatLng(order.deliveryLat!, order.deliveryLng!)
        : const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderCode),
        actions: [Padding(padding: const EdgeInsets.only(right: 12), child: StatusChip(status: order.status))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LiveTrackingMap(destination: dest, shipper: _shipper),
          const SizedBox(height: 12),
          if (order.tracking != null) ShipperCard(tracking: order.tracking!),
          const SizedBox(height: 16),
          OrderStatusStepper(currentStatus: order.status),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: MarketplaceTheme.cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tóm tắt đơn', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                ...order.items.map((i) => Text('${i.quantity}x ${i.nameSnapshot}')),
                const Divider(),
                Text('Tổng: ${order.totalAmount.toStringAsFixed(0)}đ'),
                if (order.deliveryAddress != null) Text(order.deliveryAddress!),
              ],
            ),
          ),
          if (order.status == 'Completed')
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: FilledButton(
                onPressed: () => context.push(
                  AppRoutes.marketplaceWriteReview,
                  extra: {
                    'targetType': 'Partner',
                    'targetId': order.partnerId,
                    'orderId': order.id,
                  },
                ),
                child: const Text('Đánh giá'),
              ),
            ),
        ],
      ),
    );
  }
}
