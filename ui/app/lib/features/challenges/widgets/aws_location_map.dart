import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:sync_app/core/config/aws_map_config.dart';

enum UserLocationCenterResult {
  success,
  gpsDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class MapMarkerData {
  const MapMarkerData({
    required this.id,
    required this.point,
    required this.child,
    this.onTap,
    this.alignment = Alignment.bottomCenter,
    this.width = 72,
    this.height = 88,
    this.annotationLabel,
    this.annotationColor,
    this.annotationIsCircle = false,
  });

  final String id;
  final LatLng point;
  final Widget child;
  final VoidCallback? onTap;
  final Alignment alignment;
  final double width;
  final double height;

  /// MapLibre vector map: emoji/text label or callout text.
  final String? annotationLabel;

  /// MapLibre vector map: circle fill color (origin dot).
  final Color? annotationColor;
  final bool annotationIsCircle;
}

class AwsLocationMap extends StatefulWidget {
  const AwsLocationMap({
    super.key,
    this.initialCenter,
    this.initialZoom = AwsMapConfig.defaultZoom,
    this.markers = const [],
    this.polylines = const [],
    this.walkingConnector = const [],
    this.showUserLocation = true,
    this.interactive = true,
    this.onMapReady,
    this.onTap,
    this.onGpsDisabled,
  });

  final LatLng? initialCenter;
  final double initialZoom;
  final List<MapMarkerData> markers;
  final List<LatLng> polylines;

  /// Dashed-style segment from road-snapped route end to the venue pin.
  final List<LatLng> walkingConnector;

  final bool showUserLocation;
  final bool interactive;
  final void Function(fm.MapController controller)? onMapReady;
  final void Function(LatLng point)? onTap;

  /// Fired when OS location services are off (Windows/macOS/Android GPS toggle).
  final VoidCallback? onGpsDisabled;

  @override
  State<AwsLocationMap> createState() => AwsLocationMapState();
}

class AwsLocationMapState extends State<AwsLocationMap> {
  fm.MapController? _flutterMapController;
  ml.MapLibreMapController? _mapLibreController;
  LatLng? _userLocation;
  StreamSubscription<Position>? _positionSub;
  bool _mapLibreStyleReady = false;
  final List<ml.Line> _mapLibreLines = [];
  final List<ml.Circle> _mapLibreCircles = [];
  final List<ml.Symbol> _mapLibreSymbols = [];

  bool get _useVectorMap => AwsMapConfig.usesVectorMap;

  @override
  void initState() {
    super.initState();
    if (!_useVectorMap) {
      _flutterMapController = fm.MapController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_flutterMapController != null) {
        widget.onMapReady?.call(_flutterMapController!);
      }
      if (widget.showUserLocation) _initUserLocation();
    });
  }

  @override
  void didUpdateWidget(AwsLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_useVectorMap &&
        _mapLibreStyleReady &&
        (oldWidget.polylines != widget.polylines ||
            oldWidget.walkingConnector != widget.walkingConnector ||
            oldWidget.markers != widget.markers ||
            oldWidget.showUserLocation != widget.showUserLocation)) {
      unawaited(_syncMapLibreAnnotations());
    }
  }

  Future<void> _initUserLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setFallbackUserLocation();
        _notifyGpsDisabled();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setFallbackUserLocation();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      if (!mounted) return;
      setState(() => _userLocation = LatLng(position.latitude, position.longitude));
      _startPositionStream();
      if (_mapLibreStyleReady) unawaited(_syncMapLibreAnnotations());
    } catch (_) {
      _setFallbackUserLocation();
    }
  }

  void _notifyGpsDisabled() {
    final callback = widget.onGpsDisabled;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }

  void _setFallbackUserLocation() {
    if (!mounted) return;
    setState(
      () => _userLocation = LatLng(AwsMapConfig.defaultLat, AwsMapConfig.defaultLng),
    );
  }

  void moveTo(LatLng point, {double zoom = 14}) {
    if (_mapLibreController != null) {
      _mapLibreController!.animateCamera(
        ml.CameraUpdate.newLatLngZoom(_toMl(point), zoom),
      );
      return;
    }
    _flutterMapController?.move(point, zoom);
  }

  void fitToPoints(
    List<LatLng> points, {
    EdgeInsets padding = const EdgeInsets.fromLTRB(48, 96, 48, 120),
  }) {
    if (points.length < 2) return;

    if (_mapLibreController != null) {
      final bounds = _boundsFromPoints(points);
      _mapLibreController!.animateCamera(
        ml.CameraUpdate.newLatLngBounds(
          bounds,
          left: padding.left,
          top: padding.top,
          right: padding.right,
          bottom: padding.bottom,
        ),
      );
      return;
    }

    final bounds = fm.LatLngBounds.fromPoints(points);
    _flutterMapController?.fitCamera(
      fm.CameraFit.bounds(bounds: bounds, padding: padding),
    );
  }

  Future<UserLocationCenterResult> centerOnUserLocation({double zoom = 15}) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return UserLocationCenterResult.gpsDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      return UserLocationCenterResult.permissionDenied;
    }
    if (permission == LocationPermission.deniedForever) {
      return UserLocationCenterResult.permissionDeniedForever;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return UserLocationCenterResult.unavailable;

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() => _userLocation = latLng);
      moveTo(latLng, zoom: zoom);
      _startPositionStream();
      if (_mapLibreStyleReady) unawaited(_syncMapLibreAnnotations());
      return UserLocationCenterResult.success;
    } catch (_) {
      return UserLocationCenterResult.unavailable;
    }
  }

  void _startPositionStream() {
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 25,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
        if (_mapLibreStyleReady) unawaited(_syncMapLibreAnnotations());
      }
    });
  }

  Future<void> _onMapLibreCreated(ml.MapLibreMapController controller) async {
    _mapLibreController = controller;
    await _syncMapLibreAnnotations();
  }

  Future<void> _onMapLibreStyleLoaded() async {
    _mapLibreStyleReady = true;
    await _syncMapLibreAnnotations();
  }

  Future<void> _syncMapLibreAnnotations() async {
    final controller = _mapLibreController;
    if (controller == null || !_mapLibreStyleReady) return;

    for (final line in _mapLibreLines) {
      await controller.removeLine(line);
    }
    for (final circle in _mapLibreCircles) {
      await controller.removeCircle(circle);
    }
    for (final symbol in _mapLibreSymbols) {
      await controller.removeSymbol(symbol);
    }
    _mapLibreLines.clear();
    _mapLibreCircles.clear();
    _mapLibreSymbols.clear();

    if (widget.polylines.length >= 2) {
      final line = await controller.addLine(
        ml.LineOptions(
          geometry: widget.polylines.map(_toMl).toList(),
          lineColor: '#16803A',
          lineWidth: 5,
          lineOpacity: 0.95,
        ),
      );
      _mapLibreLines.add(line);
    }

    if (widget.walkingConnector.length >= 2) {
      final connector = await controller.addLine(
        ml.LineOptions(
          geometry: widget.walkingConnector.map(_toMl).toList(),
          lineColor: '#64748B',
          lineWidth: 3,
          lineOpacity: 0.75,
        ),
      );
      _mapLibreLines.add(connector);
    }

    for (final marker in widget.markers) {
      if (marker.annotationIsCircle && marker.annotationColor != null) {
        final circle = await controller.addCircle(
          ml.CircleOptions(
            geometry: _toMl(marker.point),
            circleRadius: 8,
            circleColor: _colorToHex(marker.annotationColor!),
            circleStrokeWidth: 2,
            circleStrokeColor: '#FFFFFF',
          ),
        );
        _mapLibreCircles.add(circle);
        continue;
      }

      if (marker.annotationLabel != null && marker.annotationLabel!.isNotEmpty) {
        final symbol = await controller.addSymbol(
          ml.SymbolOptions(
            geometry: _toMl(marker.point),
            textField: marker.annotationLabel,
            textSize: marker.id == 'route-callout' ? 11 : 16,
            textColor: marker.id == 'route-callout' ? '#16803A' : '#111827',
            textHaloColor: '#FFFFFF',
            textHaloWidth: 1.5,
            textAnchor: marker.id == 'route-callout' ? 'bottom' : 'center',
          ),
        );
        _mapLibreSymbols.add(symbol);
      }
    }

    if (widget.showUserLocation && _userLocation != null) {
      final userCircle = await controller.addCircle(
        ml.CircleOptions(
          geometry: _toMl(_userLocation!),
          circleRadius: 8,
          circleColor: '#2563EB',
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _mapLibreCircles.add(userCircle);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useVectorMap) {
      return _buildMapLibre(context);
    }
    return _buildFlutterMap(context);
  }

  Widget _buildMapLibre(BuildContext context) {
    final center = widget.initialCenter ??
        _userLocation ??
        LatLng(AwsMapConfig.defaultLat, AwsMapConfig.defaultLng);
    final styleUrl = AwsMapConfig.styleDescriptorUrl!;

    assert(
      () {
        debugPrint('[AwsLocationMap] MapLibre style: $styleUrl');
        return true;
      }(),
    );

    return ml.MapLibreMap(
      styleString: styleUrl,
      initialCameraPosition: ml.CameraPosition(
        target: _toMl(center),
        zoom: widget.initialZoom,
      ),
      compassEnabled: false,
      rotateGesturesEnabled: widget.interactive,
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: false,
      onMapCreated: _onMapLibreCreated,
      onStyleLoadedCallback: _onMapLibreStyleLoaded,
      onMapClick: widget.onTap == null
          ? null
          : (_, latLng) => widget.onTap!(LatLng(latLng.latitude, latLng.longitude)),
    );
  }

  Widget _buildFlutterMap(BuildContext context) {
    final center = widget.initialCenter ??
        _userLocation ??
        LatLng(AwsMapConfig.defaultLat, AwsMapConfig.defaultLng);
    final tileUrl =
        AwsMapConfig.rasterTileUrlTemplate ?? AwsMapConfig.fallbackTileUrl;

    return fm.FlutterMap(
      mapController: _flutterMapController,
      options: fm.MapOptions(
        initialCenter: center,
        initialZoom: widget.initialZoom,
        interactionOptions: fm.InteractionOptions(
          flags: widget.interactive ? fm.InteractiveFlag.all : fm.InteractiveFlag.none,
        ),
        onTap: widget.onTap == null
            ? null
            : (_, point) => widget.onTap!(point),
      ),
      children: [
        fm.TileLayer(
          urlTemplate: tileUrl,
          userAgentPackageName: 'com.sync.sync_app',
          retinaMode: fm.RetinaMode.isHighDensity(context),
        ),
        if (widget.polylines.length >= 2)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: widget.polylines,
                color: const Color(0xFF16803A),
                strokeWidth: 5,
              ),
            ],
          ),
        if (widget.walkingConnector.length >= 2)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: widget.walkingConnector,
                color: const Color(0xFF64748B),
                strokeWidth: 3,
                borderColor: const Color(0xFF64748B),
              ),
            ],
          ),
        if (widget.showUserLocation && _userLocation != null)
          fm.MarkerLayer(
            markers: [
              fm.Marker(
                point: _userLocation!,
                width: 28,
                height: 28,
                child: const _PulsingUserDot(),
              ),
            ],
          ),
        fm.MarkerLayer(
          markers: widget.markers
              .map(
                (m) => fm.Marker(
                  point: m.point,
                  width: m.width,
                  height: m.height,
                  alignment: m.alignment,
                  child: GestureDetector(
                    onTap: m.onTap,
                    child: m.child,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

ml.LatLng _toMl(LatLng point) => ml.LatLng(point.latitude, point.longitude);

ml.LatLngBounds _boundsFromPoints(List<LatLng> points) {
  var minLat = points.first.latitude;
  var maxLat = points.first.latitude;
  var minLng = points.first.longitude;
  var maxLng = points.first.longitude;

  for (final p in points) {
    minLat = math.min(minLat, p.latitude);
    maxLat = math.max(maxLat, p.latitude);
    minLng = math.min(minLng, p.longitude);
    maxLng = math.max(maxLng, p.longitude);
  }

  return ml.LatLngBounds(
    southwest: ml.LatLng(minLat, minLng),
    northeast: ml.LatLng(maxLat, maxLng),
  );
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round();
  final g = (color.g * 255).round();
  final b = (color.b * 255).round();
  return '#${r.toRadixString(16).padLeft(2, '0')}'
      '${g.toRadixString(16).padLeft(2, '0')}'
      '${b.toRadixString(16).padLeft(2, '0')}';
}

class _PulsingUserDot extends StatefulWidget {
  const _PulsingUserDot();

  @override
  State<_PulsingUserDot> createState() => _PulsingUserDotState();
}

class _PulsingUserDotState extends State<_PulsingUserDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + _controller.value * 0.45;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 22 * scale,
              height: 22 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.22),
              ),
            ),
            child!,
          ],
        );
      },
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2563EB),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
