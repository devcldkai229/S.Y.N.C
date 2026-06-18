import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/order/data/order_remote_data_source.dart';
import 'package:sync_app/features/order/models/order_models.dart';
import 'package:sync_app/features/order/models/tracking_update.dart';
import 'package:sync_app/features/order/services/i_tracking_service.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:sync_app/features/order/widgets/eta_banner.dart';
import 'package:sync_app/features/order/widgets/live_tracking_map.dart';
import 'package:sync_app/features/order/widgets/order_summary_compact.dart';
import 'package:sync_app/features/order/widgets/tracking_shipper_card.dart';
import 'package:sync_app/features/order/widgets/tracking_status_stepper.dart';
import 'package:sync_app/features/order/utils/tracking_map_coords.dart';
import 'package:sync_app/features/order/utils/tracking_status_mapper.dart';
import 'package:sync_app/shared/widgets/app_shell_overlay_scaffold.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _api = getIt<OrderRemoteDataSource>();
  late final ITrackingService _tracking = getIt<ITrackingService>();

  OrderSummary? _order;
  TrackingUpdate? _update;
  StreamSubscription<TrackingUpdate>? _sub;
  final _stepTimes = <String, DateTime>{};
  String? _error;

  LatLng get _pickup {
    final t = _order?.tracking;
    final fallback = const LatLng(10.7769, 106.7009);
    if (t?.pickupLat != null && t?.pickupLng != null) {
      return TrackingMapCoords.sanitize(
        LatLng(t!.pickupLat!, t.pickupLng!),
        fallback,
      );
    }
    return fallback;
  }

  LatLng get _dropoff {
    final o = _order;
    final fallback = LatLng(_pickup.latitude + 0.01, _pickup.longitude + 0.01);
    if (o?.deliveryLat != null && o?.deliveryLng != null) {
      return TrackingMapCoords.sanitize(
        LatLng(o!.deliveryLat!, o.deliveryLng!),
        fallback,
      );
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final order = await _api.getOrder(widget.orderId);
      if (!mounted) return;

      setState(() {
        _order = order;
        _error = null;
      });

      final session = TrackingSession(
        orderId: widget.orderId,
        pickupLat: _pickup.latitude,
        pickupLng: _pickup.longitude,
        dropoffLat: _dropoff.latitude,
        dropoffLng: _dropoff.longitude,
      );

      _sub = _tracking.watch(session).listen(_applyTrackingUpdate);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Không tải được đơn hàng. Vui lòng thử lại.');
    }
  }

  void _applyTrackingUpdate(TrackingUpdate u) {
    if (!mounted) return;
    final prev = _update;
    if (prev != null &&
        prev.orderStatus == u.orderStatus &&
        prev.deliveryStatus == u.deliveryStatus &&
        prev.statusMessage == u.statusMessage &&
        prev.etaMinutes == u.etaMinutes &&
        TrackingMapCoords.sameLatLngValues(
          prev.shipperLat,
          prev.shipperLng,
          u.shipperLat,
          u.shipperLng,
        )) {
      return;
    }
    setState(() {
      _update = u;
      _stepTimes.putIfAbsent(u.orderStatus, () => u.timestamp);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    unawaited(_tracking.stop());
    super.dispose();
  }

  List<DateTime?> _stepTimestamps() {
    const order = ['Confirmed', 'Preparing', 'PickedUp', 'Delivering', 'Delivered'];
    return order.map((s) => _stepTimes[s]).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return AppShellOverlayScaffold(
        child: Scaffold(
          backgroundColor: OrderTheme.background,
          appBar: AppBar(
            backgroundColor: OrderTheme.background,
            title: const Text('Theo dõi đơn hàng'),
          ),
          body: Center(child: Text(_error!)),
        ),
      );
    }

    final order = _order;
    if (order == null) {
      return AppShellOverlayScaffold(
        child: Scaffold(
          backgroundColor: OrderTheme.background,
          appBar: AppBar(
            backgroundColor: OrderTheme.background,
            title: const Text('Theo dõi đơn hàng'),
          ),
          body: const Center(child: CircularProgressIndicator(color: OrderTheme.accent)),
        ),
      );
    }

    final update = _update;
    final status = update?.orderStatus ??
        TrackingStatusMapper.displayOrderStatus(
          orderStatus: order.status,
          deliveryStatus: order.tracking?.status ?? 'Pending',
        );
    final shipperPoint = TrackingMapCoords.resolveShipper(
      pickup: _pickup,
      lat: update?.shipperLat,
      lng: update?.shipperLng,
      deliveryStatus: update?.deliveryStatus ?? order.tracking?.status,
    );
    final mapHeight = MediaQuery.sizeOf(context).height * 0.46;
    final isDelivered = status == 'Delivered' || status == 'Completed';

    return AppShellOverlayScaffold(
      child: Scaffold(
        backgroundColor: OrderTheme.background,
        appBar: AppBar(
          backgroundColor: OrderTheme.background,
          elevation: 0,
          foregroundColor: OrderTheme.textPrimary,
          title: const Text('Theo dõi đơn hàng', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Column(
          children: [
            SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: LiveTrackingMap(
                key: ValueKey(widget.orderId),
                pickup: _pickup,
                destination: _dropoff,
                shipper: shipperPoint,
                followShipper: const {'Preparing', 'PickedUp', 'Delivering'}.contains(status),
                height: mapHeight,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  EtaBanner(
                    etaMinutes: update?.etaMinutes,
                    statusMessage: update?.statusMessage,
                    isDelivered: isDelivered,
                  ),
                  const SizedBox(height: 20),
                  TrackingStatusStepper(
                    currentStatus: status,
                    timestamps: _stepTimestamps(),
                  ),
                  if (update?.shipper != null) ...[
                    const SizedBox(height: 16),
                    TrackingShipperCard(shipper: update!.shipper!),
                  ] else if (order.tracking?.shipperName != null) ...[
                    const SizedBox(height: 16),
                    TrackingShipperCard(
                      shipper: ShipperInfo(
                        name: order.tracking!.shipperName!,
                        plateNumber: order.tracking!.shipperPlateNumber ?? '—',
                        phone: order.tracking!.shipperPhone,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  OrderSummaryCompact(order: order),
                  if (isDelivered) ...[
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
      ),
    );
  }
}
