import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';
import 'package:sync_app/features/order/utils/tracking_map_coords.dart';

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

class _LiveTrackingMapState extends State<LiveTrackingMap> with SingleTickerProviderStateMixin {
  final _mapKey = GlobalKey<AwsLocationMapState>();
  AnimationController? _anim;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  LatLng? _displayShipper;
  bool _mapReady = false;

  static const _defaultCenter = LatLng(10.7769, 106.7009);

  LatLng get _pickup =>
      TrackingMapCoords.sanitize(widget.pickup, _defaultCenter);

  LatLng get _destination =>
      TrackingMapCoords.sanitize(widget.destination, LatLng(_pickup.latitude + 0.01, _pickup.longitude + 0.01));

  @override
  void initState() {
    super.initState();
    _displayShipper = widget.shipper;
  }

  @override
  void didUpdateWidget(LiveTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.shipper != null && widget.shipper != oldWidget.shipper) {
      final from = _displayShipper ?? oldWidget.shipper ?? widget.shipper!;
      if (from == widget.shipper) {
        setState(() => _displayShipper = widget.shipper);
      } else {
        _animateShipper(from, widget.shipper!);
      }
    } else if (widget.shipper == null) {
      setState(() => _displayShipper = null);
    }

    if (oldWidget.pickup != widget.pickup ||
        oldWidget.destination != widget.destination ||
        oldWidget.shipper != widget.shipper) {
      _scheduleFitBounds();
    }
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
      if (_displayShipper ?? widget.shipper case final p?) p,
    ];
    _mapKey.currentState?.fitToPoints(points);
  }

  void _animateShipper(LatLng from, LatLng to) {
    _anim?.dispose();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _latAnim = Tween<double>(begin: from.latitude, end: to.latitude)
        .animate(CurvedAnimation(parent: _anim!, curve: Curves.easeInOut));
    _lngAnim = Tween<double>(begin: from.longitude, end: to.longitude)
        .animate(CurvedAnimation(parent: _anim!, curve: Curves.easeInOut));
    _anim!.addListener(() {
      if (_latAnim == null || _lngAnim == null) return;
      final point = LatLng(_latAnim!.value, _lngAnim!.value);
      setState(() => _displayShipper = point);
      if (widget.followShipper) {
        _mapKey.currentState?.moveTo(point);
      }
    });
    _anim!.forward();
  }

  @override
  void dispose() {
    _anim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipperPoint = _displayShipper ?? widget.shipper;
    final center = shipperPoint ?? _destination;

    final markers = <MapMarkerData>[
      MapMarkerData(
        id: 'kitchen',
        point: _pickup,
        child: const Icon(Icons.storefront_outlined, color: OrderTheme.accent, size: 30),
        annotationIsCircle: true,
        annotationColor: OrderTheme.accent,
      ),
      MapMarkerData(
        id: 'dest',
        point: _destination,
        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        annotationIsCircle: true,
        annotationColor: Colors.red,
      ),
      if (shipperPoint != null)
        MapMarkerData(
          id: 'shipper',
          point: shipperPoint,
          child: const Icon(Icons.two_wheeler, color: OrderTheme.accent, size: 30),
          annotationIsCircle: true,
          annotationColor: const Color(0xFF2563EB),
        ),
    ];

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AwsLocationMap(
        key: _mapKey,
        initialCenter: center,
        initialZoom: 14,
        markers: markers,
        showUserLocation: false,
        onReady: () {
          _mapReady = true;
          _fitBounds();
        },
      ),
    );
  }
}
