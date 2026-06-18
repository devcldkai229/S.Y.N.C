import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/order/utils/map_pin_bitmap_factory.dart';
import 'package:sync_app/features/order/utils/tracking_map_coords.dart';
import 'package:sync_app/features/order/widgets/tracking_map_pin.dart';

class LiveTrackingMap extends StatefulWidget {
  const LiveTrackingMap({
    super.key,
    required this.pickup,
    required this.destination,
    this.shipper,
    this.followShipper = false,
    this.height = 260,
  });

  final LatLng pickup;
  final LatLng destination;
  final LatLng? shipper;
  final bool followShipper;
  final double height;

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> with TickerProviderStateMixin {
  final _mapKey = GlobalKey<AwsLocationMapState>();
  late final AnimationController _shipperAnim;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  LatLng? _displayShipper;
  bool _mapReady = false;
  late LatLng _initialCenter;

  /// Short tween between realtime GPS steps — sandbox/API often sends ~200m hops.
  static const _shipperAnimDuration = Duration(milliseconds: 500);

  static const _defaultCenter = LatLng(10.7769, 106.7009);

  LatLng get _pickup =>
      TrackingMapCoords.sanitize(widget.pickup, _defaultCenter);

  LatLng get _destination =>
      TrackingMapCoords.sanitize(
        widget.destination,
        LatLng(_pickup.latitude + 0.01, _pickup.longitude + 0.01),
      );

  @override
  void initState() {
    super.initState();
    _displayShipper = widget.shipper;
    _initialCenter = widget.shipper ?? _destination;
    _shipperAnim = AnimationController(vsync: this, duration: _shipperAnimDuration)
      ..addListener(_onShipperAnimationTick);
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!TrackingMapCoords.samePoint(widget.shipper, oldWidget.shipper)) {
      _applyShipperTarget(widget.shipper);
    }

    if (!TrackingMapCoords.samePoint(widget.pickup, oldWidget.pickup) ||
        !TrackingMapCoords.samePoint(widget.destination, oldWidget.destination)) {
      setState(() {});
      _scheduleFitBounds();
    }
  }

  void _applyShipperTarget(LatLng? target) {
    if (target == null) {
      _shipperAnim
        ..stop()
        ..reset();
      _displayShipper = null;
      _mapKey.currentState?.removeDynamicMarker('shipper');
      return;
    }

    final from = _displayShipper ?? target;
    if (TrackingMapCoords.samePoint(from, target)) {
      if (_displayShipper == null) {
        _displayShipper = target;
        _upsertShipperMarker(target);
      }
      return;
    }

    _runShipperTween(from, target);
  }

  MapMarkerData _shipperMarkerData(LatLng point) => MapMarkerData(
        id: 'shipper',
        point: point,
        child: const TrackingMapPin(
          icon: Icons.two_wheeler_rounded,
          label: TrackingMapMarkerStyle.driverLabel,
          color: TrackingMapMarkerStyle.driverColor,
        ),
        iconImageId: MapPinBitmapFactory.driverImageId,
        annotationLabel: TrackingMapMarkerStyle.driverLabel,
        annotationColor: TrackingMapMarkerStyle.driverColor,
        width: 80,
        height: 72,
        alignment: Alignment.bottomCenter,
      );

  void _upsertShipperMarker(LatLng point) {
    _mapKey.currentState?.upsertDynamicMarker(_shipperMarkerData(point));
  }

  void _scheduleFitBounds() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _fitBounds();
    });
  }

  void _fitBounds() {
    final points = [
      _pickup,
      _destination,
      ?(_displayShipper ?? widget.shipper),
    ];
    _mapKey.currentState?.fitToPoints(points);
  }

  void _runShipperTween(LatLng from, LatLng to) {
    _displayShipper = from;
    _upsertShipperMarker(from);

    _latAnim = Tween<double>(begin: from.latitude, end: to.latitude).animate(
      CurvedAnimation(parent: _shipperAnim, curve: Curves.linear),
    );
    _lngAnim = Tween<double>(begin: from.longitude, end: to.longitude).animate(
      CurvedAnimation(parent: _shipperAnim, curve: Curves.linear),
    );

    _shipperAnim
      ..stop()
      ..reset()
      ..forward();
  }

  void _onShipperAnimationTick() {
    if (!mounted || _latAnim == null || _lngAnim == null) return;

    final point = LatLng(_latAnim!.value, _lngAnim!.value);
    _displayShipper = point;
    _mapKey.currentState?.updateMarkerPosition('shipper', point);

    if (widget.followShipper) {
      _mapKey.currentState?.moveTo(point);
    }

    if (_shipperAnim.isCompleted && widget.shipper != null) {
      _displayShipper = widget.shipper;
    }
  }

  @override
  void dispose() {
    _shipperAnim
      ..removeListener(_onShipperAnimationTick)
      ..dispose();
    super.dispose();
  }

  List<MapMarkerData> get _staticMarkers => [
        MapMarkerData(
          id: 'kitchen',
          point: _pickup,
          child: const TrackingMapPin(
            icon: Icons.restaurant_rounded,
            label: TrackingMapMarkerStyle.restaurantLabel,
            color: TrackingMapMarkerStyle.restaurantColor,
          ),
          iconImageId: MapPinBitmapFactory.restaurantImageId,
          annotationLabel: TrackingMapMarkerStyle.restaurantLabel,
          annotationColor: TrackingMapMarkerStyle.restaurantColor,
          width: 80,
          height: 72,
          alignment: Alignment.bottomCenter,
        ),
        MapMarkerData(
          id: 'dest',
          point: _destination,
          child: const TrackingMapPin(
            icon: Icons.home_rounded,
            label: TrackingMapMarkerStyle.userLabel,
            color: TrackingMapMarkerStyle.userColor,
          ),
          iconImageId: MapPinBitmapFactory.userImageId,
          annotationLabel: TrackingMapMarkerStyle.userLabel,
          annotationColor: TrackingMapMarkerStyle.userColor,
          width: 80,
          height: 72,
          alignment: Alignment.bottomCenter,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AwsLocationMap(
        key: _mapKey,
        initialCenter: _initialCenter,
        initialZoom: 14,
        markers: _staticMarkers,
        showUserLocation: false,
        onReady: () {
          _mapReady = true;
          final shipper = widget.shipper ?? _displayShipper;
          if (shipper != null) {
            _displayShipper ??= shipper;
            _upsertShipperMarker(_displayShipper!);
          }
          _fitBounds();
        },
      ),
    );
  }
}
