import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/order/theme/order_theme.dart';

/// OSM map for tracking demo.
/// SWAP: replace with [AwsLocationMap] when AWS Location is configured.
class DemoTrackingMap extends StatefulWidget {
  const DemoTrackingMap({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.shipper,
    this.followShipper = false,
  });

  final LatLng pickup;
  final LatLng dropoff;
  final LatLng? shipper;
  final bool followShipper;

  @override
  State<DemoTrackingMap> createState() => _DemoTrackingMapState();
}

class _DemoTrackingMapState extends State<DemoTrackingMap> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  AnimationController? _anim;
  Animation<double>? _latAnim;
  Animation<double>? _lngAnim;
  LatLng? _displayShipper;
  bool _fitted = false;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  @override
  void didUpdateWidget(DemoTrackingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shipper != null && widget.shipper != oldWidget.shipper) {
      final from = _displayShipper ?? oldWidget.shipper ?? widget.shipper!;
      if (from == widget.shipper) {
        setState(() => _displayShipper = widget.shipper);
      } else {
        _animateShipper(from, widget.shipper!);
      }
    }
    if (!_fitted) _fitBounds();
  }

  void _fitBounds() {
    final points = [widget.pickup, widget.dropoff, if (widget.shipper != null) widget.shipper!];
    if (points.length < 2) return;

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }

    final bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
    _fitted = true;
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
      setState(() => _displayShipper = LatLng(_latAnim!.value, _lngAnim!.value));
      if (widget.followShipper) {
        _mapController.move(_displayShipper!, _mapController.camera.zoom);
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
    final shipper = _displayShipper ?? widget.shipper;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.pickup,
        initialZoom: 13,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.sync.app',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: widget.pickup,
              width: 36,
              height: 36,
              child: const _MapPin(icon: Icons.storefront_outlined, filled: false),
            ),
            Marker(
              point: widget.dropoff,
              width: 36,
              height: 36,
              child: const _MapPin(icon: Icons.location_on_outlined, filled: true),
            ),
            if (shipper != null)
              Marker(
                point: shipper,
                width: 40,
                height: 40,
                child: const _MapPin(icon: Icons.two_wheeler_outlined, filled: true, accent: true),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    this.filled = false,
    this.accent = false,
  });

  final IconData icon;
  final bool filled;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: accent ? OrderTheme.accent : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: accent ? OrderTheme.accent : OrderTheme.line, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: accent ? Colors.white : OrderTheme.textMuted,
      ),
    );
  }
}
