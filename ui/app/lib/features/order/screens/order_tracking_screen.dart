import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/config/mock_tracking_config.dart';
import 'package:sync_app/features/order/data/order_demo_repository.dart';
import 'package:sync_app/features/order/mock/order_demo_data.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:sync_app/features/order/widgets/demo_tracking_map.dart';
import 'package:sync_app/features/order/widgets/eta_banner.dart';
import 'package:sync_app/features/order/widgets/order_summary_compact.dart';
import 'package:sync_app/features/order/widgets/tracking_shipper_card.dart';
import 'package:sync_app/features/order/widgets/tracking_status_stepper.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _demoRepo = getIt<OrderDemoRepository>();
  late final ITrackingService _tracking = getIt<ITrackingService>();

  OrderSummary? _order;
  TrackingUpdate? _update;
  StreamSubscription<TrackingUpdate>? _sub;
  final _stepTimes = <String, DateTime>{};

  LatLng get _pickup => const LatLng(MockTrackingConfig.pickupLat, MockTrackingConfig.pickupLng);

  LatLng get _dropoff {
    final o = _order;
    if (o?.deliveryLat != null && o?.deliveryLng != null) {
      return LatLng(o!.deliveryLat!, o.deliveryLng!);
    }
    return const LatLng(MockTrackingConfig.fallbackDropLat, MockTrackingConfig.fallbackDropLng);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _demoRepo.loadOrders();
    if (!mounted) return;

    final order = _demoRepo.getOrder(widget.orderId) ??
        (widget.orderId == MockTrackingConfig.demoActiveOrderId
            ? OrderDemoData.activeOrder()
            : null);
    if (!mounted) return;

    if (order == null) {
      setState(() => _order = null);
      return;
    }

    setState(() => _order = order);

    final session = TrackingSession(
      orderId: widget.orderId,
      pickupLat: MockTrackingConfig.pickupLat,
      pickupLng: MockTrackingConfig.pickupLng,
      dropoffLat: order.deliveryLat ?? MockTrackingConfig.fallbackDropLat,
      dropoffLng: order.deliveryLng ?? MockTrackingConfig.fallbackDropLng,
    );

    _sub = _tracking.watch(session).listen((u) {
      if (!mounted) return;
      setState(() {
        _update = u;
        _stepTimes.putIfAbsent(u.orderStatus, () => u.timestamp);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tracking.stop();
    super.dispose();
  }

  List<DateTime?> _stepTimestamps() {
    const order = ['Confirmed', 'Preparing', 'PickedUp', 'Delivering', 'Delivered'];
    return order.map((s) => _stepTimes[s]).toList();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    if (order == null) {
      return Scaffold(
        backgroundColor: OrderTheme.background,
        appBar: AppBar(backgroundColor: OrderTheme.background, title: const Text('Theo dõi đơn')),
        body: const Center(child: Text('Không tìm thấy đơn demo')),
      );
    }

    final update = _update;
    final status = update?.orderStatus ?? order.status;
    final shipperPoint = update?.shipperLat != null && update?.shipperLng != null
        ? LatLng(update!.shipperLat!, update.shipperLng!)
        : null;
    final mapHeight = MediaQuery.sizeOf(context).height * 0.46;

    return Scaffold(
      backgroundColor: OrderTheme.background,
      appBar: AppBar(
        backgroundColor: OrderTheme.background,
        elevation: 0,
        foregroundColor: OrderTheme.textPrimary,
        title: Text(order.orderCode, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          SizedBox(
            height: mapHeight,
            width: double.infinity,
            child: DemoTrackingMap(
              pickup: _pickup,
              dropoff: _dropoff,
              shipper: update?.showShipperMarker == true ? shipperPoint : null,
              followShipper: status == 'Delivering',
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                EtaBanner(
                  etaMinutes: update?.etaMinutes,
                  statusMessage: update?.statusMessage,
                  isDelivered: status == 'Delivered',
                ),
                const SizedBox(height: 20),
                TrackingStatusStepper(
                  currentStatus: status,
                  timestamps: _stepTimestamps(),
                ),
                if (update?.shipper != null) ...[
                  const SizedBox(height: 16),
                  TrackingShipperCard(shipper: update!.shipper!),
                ],
                const SizedBox(height: 16),
                OrderSummaryCompact(order: order),
                if (status == 'Delivered') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.push(
                        AppRoutes.marketplaceWriteReview,
                        extra: {
                          'targetType': 'Partner',
                          'targetId': order.partnerId,
                          'orderId': order.id,
                        },
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: OrderTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Đánh giá'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
