import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:sync_app/core/config/aws_map_config.dart';
import 'package:sync_app/features/challenges/models/challenge_route_models.dart';
import 'package:sync_app/features/order/utils/map_pin_bitmap_factory.dart';

const _pickerCenterMinMoveMeters = 12.0;
const _markerTapThresholdMeters = 80.0;
const _distance = Distance();

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
    this.iconImageId,
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

  /// MapLibre: registered [MapPinBitmapFactory] image id (icon pin instead of dot).
  final String? iconImageId;
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
    this.onReady,
    this.pickerMode = false,
    this.onPickerCenterChanged,
  });

  final LatLng? initialCenter;
  final double initialZoom;
  final List<MapMarkerData> markers;
  final List<LatLng> polylines;

  /// Dashed-style segment from road-snapped route end to the venue pin.
  final List<LatLng> walkingConnector;

  final bool showUserLocation;
  final bool interactive;

  /// Center-pin picker: reports map center after pan/zoom (debounce in parent).
  final bool pickerMode;
  final void Function(LatLng center)? onPickerCenterChanged;

  final void Function(fm.MapController controller)? onMapReady;
  final void Function(LatLng point)? onTap;

  /// Fired when OS location services are off (Windows/macOS/Android GPS toggle).
  final VoidCallback? onGpsDisabled;

  /// Fired once a map controller (MapLibre or FlutterMap) is ready.
  final VoidCallback? onReady;

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
  final Map<String, _MarkerHandle> _markerHandles = {};
  final Map<String, MapMarkerData> _pendingDynamicMarkers = {};
  ml.Circle? _userLocationCircle;
  Timer? _pickerCenterDebounce;
  LatLng? _lastPickerCenterNotified;
  LatLng? _lastCenteredLocation;
  bool _readyNotified = false;

  /// Last point passed to [moveTo] / [centerOnUserLocation] (picker GPS / search).
  LatLng? get lastCenteredLocation => _lastCenteredLocation;

  /// Grab/sync-map keys only authorize style-descriptor (v0), not v2 raster tiles.
  bool get _useVectorMap => AwsMapConfig.styleDescriptorUrl != null;

  @override
  void initState() {
    super.initState();
    if (!_useVectorMap) {
      _flutterMapController = fm.MapController();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_flutterMapController != null) {
        widget.onMapReady?.call(_flutterMapController!);
        _notifyReady();
      }
      if (widget.showUserLocation) _initUserLocation();
    });
  }

  void _notifyReady() {
    if (_readyNotified) return;
    _readyNotified = true;
    widget.onReady?.call();
  }

  @override
  void didUpdateWidget(AwsLocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_useVectorMap &&
        _mapLibreStyleReady &&
        (oldWidget.polylines != widget.polylines ||
            oldWidget.walkingConnector != widget.walkingConnector ||
            _markersChanged(oldWidget.markers, widget.markers) ||
            oldWidget.showUserLocation != widget.showUserLocation)) {
      unawaited(_syncMapLibreAnnotations());
    }
  }

  static bool _markersChanged(List<MapMarkerData> old, List<MapMarkerData> neu) {
    if (old.length != neu.length) return true;
    for (var i = 0; i < old.length; i++) {
      if (old[i].id != neu[i].id) return true;
      final a = old[i].point;
      final b = neu[i].point;
      if ((a.latitude - b.latitude).abs() > 1e-9 ||
          (a.longitude - b.longitude).abs() > 1e-9) {
        return true;
      }
    }
    return false;
  }

  Future<void> _initUserLocation() async {
    try {
      if (!kIsWeb) {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _setFallbackUserLocation();
          _notifyGpsDisabled();
          return;
        }
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

  LatLng? get mapCenter {
    final mlTarget = _mapLibreController?.cameraPosition?.target;
    if (mlTarget != null) {
      return LatLng(mlTarget.latitude, mlTarget.longitude);
    }
    return _flutterMapController?.camera.center;
  }

  Future<void> moveTo(LatLng point, {double zoom = 14}) async {
    _lastCenteredLocation = point;
    if (widget.pickerMode) {
      _lastPickerCenterNotified = point;
    }
    if (_mapLibreController != null) {
      await _mapLibreController!.animateCamera(
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

  /// Registers a route-distance callout bitmap for MapLibre and returns its image id.
  Future<String?> registerRouteCalloutImage(TravelModeRouteInfo info) async {
    final controller = _mapLibreController;
    if (controller == null || !_mapLibreStyleReady) return null;
    return MapPinBitmapFactory.registerRouteCallout(controller, info);
  }

  /// Forces MapLibre circles/symbols to match current [AwsLocationMap.markers].
  void refreshAnnotations() {
    if (_useVectorMap && _mapLibreStyleReady) {
      unawaited(_syncMapLibreAnnotations());
    }
  }

  /// Adds or updates a marker managed outside [AwsLocationMap.markers] (e.g. live shipper).
  Future<void> upsertDynamicMarker(MapMarkerData marker) async {
    if (!_mapLibreStyleReady || _mapLibreController == null) {
      _pendingDynamicMarkers[marker.id] = marker;
      if (!_useVectorMap && mounted) {
        setState(() {});
      }
      return;
    }

    final existing = _markerHandles[marker.id];
    if (existing != null && existing.isDynamic) {
      existing.markerData = marker;
      await updateMarkerPosition(marker.id, marker.point);
      return;
    }
    await _createMarkerHandle(marker, isDynamic: true);
  }

  /// Moves an existing marker without rebuilding the map widget.
  Future<void> updateMarkerPosition(String markerId, LatLng point) async {
    final pending = _pendingDynamicMarkers[markerId];
    if (pending != null) {
      _pendingDynamicMarkers[markerId] = MapMarkerData(
        id: pending.id,
        point: point,
        child: pending.child,
        onTap: pending.onTap,
        alignment: pending.alignment,
        width: pending.width,
        height: pending.height,
        annotationLabel: pending.annotationLabel,
        annotationColor: pending.annotationColor,
        annotationIsCircle: pending.annotationIsCircle,
        iconImageId: pending.iconImageId,
      );
      if (!_useVectorMap && mounted) {
        setState(() {});
      }
      return;
    }

    final handle = _markerHandles[markerId];
    if (handle == null) return;

    handle.point = point;
    final controller = _mapLibreController;
    if (_useVectorMap && controller != null && _mapLibreStyleReady) {
      if (handle.circle != null) {
        await controller.updateCircle(
          handle.circle!,
          ml.CircleOptions(geometry: _toMl(point)),
        );
      }
      if (handle.symbol != null) {
        await controller.updateSymbol(
          handle.symbol!,
          ml.SymbolOptions(geometry: _toMl(point)),
        );
      }
      return;
    }

    if (handle.isDynamic && mounted) {
      setState(() {});
    }
  }

  Future<void> removeDynamicMarker(String markerId) async {
    _pendingDynamicMarkers.remove(markerId);
    final handle = _markerHandles[markerId];
    if (handle == null || !handle.isDynamic) {
      if (!_useVectorMap && mounted) {
        setState(() {});
      }
      return;
    }
    await _removeMarkerHandle(markerId);
    if (!_useVectorMap && mounted) {
      setState(() {});
    }
  }

  Future<UserLocationCenterResult> centerOnUserLocation({double zoom = 15}) async {
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return UserLocationCenterResult.gpsDisabled;
    }

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
      await moveTo(latLng, zoom: zoom);
      _startPositionStream();
      if (_mapLibreStyleReady) unawaited(_syncMapLibreAnnotations());
      return UserLocationCenterResult.success;
    } catch (_) {
      return UserLocationCenterResult.unavailable;
    }
  }

  void _startPositionStream() {
    if (widget.pickerMode) return;

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

  bool _pickerCenterMovedEnough(LatLng center) {
    final last = _lastPickerCenterNotified;
    if (last == null) return true;
    return _distance.as(LengthUnit.Meter, last, center) >= _pickerCenterMinMoveMeters;
  }

  void _notifyPickerCenter({bool immediate = false}) {
    if (!widget.pickerMode) return;
    final center = mapCenter;
    if (center == null) return;
    if (!_pickerCenterMovedEnough(center)) return;

    void emit() {
      final latest = mapCenter;
      if (latest == null || !mounted) return;
      if (!_pickerCenterMovedEnough(latest)) return;
      _lastPickerCenterNotified = latest;
      widget.onPickerCenterChanged?.call(latest);
    }

    _pickerCenterDebounce?.cancel();
    if (immediate) {
      emit();
      return;
    }
    _pickerCenterDebounce = Timer(const Duration(milliseconds: 300), emit);
  }

  Future<void> _onMapLibreCreated(ml.MapLibreMapController controller) async {
    _mapLibreController = controller;
    _notifyReady();
    await _syncMapLibreAnnotations();
  }

  Future<void> _onMapLibreStyleLoaded() async {
    _mapLibreStyleReady = true;
    final controller = _mapLibreController;
    if (controller != null) {
      await MapPinBitmapFactory.registerAll(controller);
    }
    await _syncMapLibreAnnotations();
    await _flushPendingDynamicMarkers();
  }

  Future<void> _flushPendingDynamicMarkers() async {
    if (_pendingDynamicMarkers.isEmpty) return;
    final pending = Map<String, MapMarkerData>.from(_pendingDynamicMarkers);
    _pendingDynamicMarkers.clear();
    for (final marker in pending.values) {
      await upsertDynamicMarker(marker);
    }
  }

  Future<void> _syncMapLibreAnnotations() async {
    final controller = _mapLibreController;
    if (controller == null || !_mapLibreStyleReady) return;

    for (final line in _mapLibreLines) {
      await controller.removeLine(line);
    }
    _mapLibreLines.clear();

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

    final widgetIds = {for (final marker in widget.markers) marker.id};
    for (final id in _markerHandles.keys.toList()) {
      final handle = _markerHandles[id]!;
      if (!handle.isDynamic && !widgetIds.contains(id)) {
        await _removeMarkerHandle(id);
      }
    }

    for (final marker in widget.markers) {
      await _upsertStaticMarker(marker);
    }

    await _syncUserLocationCircle();
  }

  Future<void> _upsertStaticMarker(MapMarkerData marker) async {
    final existing = _markerHandles[marker.id];
    if (existing != null && !existing.isDynamic) {
      if (existing.sameMarker(marker)) {
        if (!existing.samePoint(marker.point)) {
          await updateMarkerPosition(marker.id, marker.point);
        }
        return;
      }
      await _removeMarkerHandle(marker.id);
    }
    await _createMarkerHandle(marker, isDynamic: false);
  }

  Future<void> _createMarkerHandle(MapMarkerData marker, {required bool isDynamic}) async {
    final controller = _mapLibreController;
    if (controller == null || !_mapLibreStyleReady) return;

    final handle = _MarkerHandle(
      isDynamic: isDynamic,
      point: marker.point,
      markerData: marker,
    );

    if (marker.iconImageId != null) {
      handle.symbol = await controller.addSymbol(
        ml.SymbolOptions(
          geometry: _toMl(marker.point),
          iconImage: marker.iconImageId,
          iconSize: marker.id == 'route-callout' ? 1.05 : 1.0,
          iconAnchor: 'bottom',
        ),
      );
    } else if (marker.annotationIsCircle && marker.annotationColor != null) {
      handle.circle = await controller.addCircle(
        ml.CircleOptions(
          geometry: _toMl(marker.point),
          circleRadius: marker.annotationLabel != null ? 11 : 8,
          circleColor: _colorToHex(marker.annotationColor!),
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );

      if (marker.annotationLabel != null && marker.annotationLabel!.isNotEmpty) {
        handle.symbol = await controller.addSymbol(
          ml.SymbolOptions(
            geometry: _toMl(marker.point),
            textField: marker.annotationLabel,
            textSize: 11,
            textColor: _colorToHex(marker.annotationColor!),
            textHaloColor: '#FFFFFF',
            textHaloWidth: 2.5,
            textAnchor: 'top',
            textOffset: const Offset(0, 1.4),
          ),
        );
      }
    } else if (marker.annotationLabel != null && marker.annotationLabel!.isNotEmpty) {
      if (_labelUsesEmojiGlyphs(marker.annotationLabel!)) {
        final fill = marker.annotationColor ?? const Color(0xFF16803A);
        handle.circle = await controller.addCircle(
          ml.CircleOptions(
            geometry: _toMl(marker.point),
            circleRadius: 10,
            circleColor: _colorToHex(fill),
            circleStrokeWidth: 2.5,
            circleStrokeColor: '#FFFFFF',
          ),
        );
      } else {
        handle.symbol = await controller.addSymbol(
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
      }
    }

    _markerHandles[marker.id] = handle;
    if (isDynamic && !_useVectorMap && mounted) {
      setState(() {});
    }
  }

  Future<void> _removeMarkerHandle(String markerId) async {
    final handle = _markerHandles.remove(markerId);
    if (handle == null) return;

    final controller = _mapLibreController;
    if (controller == null) return;

    if (handle.circle != null) {
      await controller.removeCircle(handle.circle!);
    }
    if (handle.symbol != null) {
      await controller.removeSymbol(handle.symbol!);
    }
  }

  Future<void> _syncUserLocationCircle() async {
    final controller = _mapLibreController;
    if (controller == null || !_mapLibreStyleReady) return;

    if (!widget.showUserLocation || _userLocation == null) {
      if (_userLocationCircle != null) {
        await controller.removeCircle(_userLocationCircle!);
        _userLocationCircle = null;
      }
      return;
    }

    if (_userLocationCircle != null) {
      await controller.updateCircle(
        _userLocationCircle!,
        ml.CircleOptions(geometry: _toMl(_userLocation!)),
      );
      return;
    }

    _userLocationCircle = await controller.addCircle(
      ml.CircleOptions(
        geometry: _toMl(_userLocation!),
        circleRadius: 8,
        circleColor: '#2563EB',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ),
    );
  }

  void _handleMapTap(LatLng point) {
    widget.onTap?.call(point);
    _tryInvokeMarkerTap(point);
  }

  void _tryInvokeMarkerTap(LatLng point) {
    MapMarkerData? nearest;
    var nearestMeters = double.infinity;

    for (final marker in widget.markers) {
      if (marker.onTap == null) continue;
      final meters = _distance.as(LengthUnit.Meter, marker.point, point);
      if (meters <= _markerTapThresholdMeters && meters < nearestMeters) {
        nearestMeters = meters;
        nearest = marker;
      }
    }

    nearest?.onTap?.call();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pickerCenterDebounce?.cancel();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        return SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: ml.MapLibreMap(
            key: const ValueKey('sync_maplibre'),
            styleString: styleUrl,
            // Symbol taps on web can report null feature id → maplibre_gl crash.
            annotationConsumeTapEvents: const [ml.AnnotationType.fill],
            initialCameraPosition: ml.CameraPosition(
              target: _toMl(center),
              zoom: widget.initialZoom,
            ),
            compassEnabled: false,
            rotateGesturesEnabled: widget.interactive,
            scrollGesturesEnabled: widget.interactive,
            zoomGesturesEnabled: widget.interactive,
            tiltGesturesEnabled: false,
            trackCameraPosition: widget.pickerMode,
            onMapCreated: _onMapLibreCreated,
            onStyleLoadedCallback: _onMapLibreStyleLoaded,
            onCameraIdle: widget.pickerMode ? _notifyPickerCenter : null,
            onMapClick: widget.interactive
                ? (_, latLng) => _handleMapTap(LatLng(latLng.latitude, latLng.longitude))
                : null,
          ),
        );
      },
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
        onMapEvent: widget.pickerMode
            ? (event) {
                if (event is fm.MapEventMoveEnd) {
                  _notifyPickerCenter(immediate: true);
                }
              }
            : null,
        onPositionChanged: widget.pickerMode
            ? (position, hasGesture) {
                if (hasGesture) _notifyPickerCenter();
              }
            : null,
        onTap: widget.onTap == null && widget.markers.every((m) => m.onTap == null)
            ? null
            : (_, point) => _handleMapTap(point),
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
          markers: [
            ...widget.markers.map(
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
            ),
            ..._markerHandles.values
                .where((handle) => handle.isDynamic && handle.markerData != null)
                .map(
                  (handle) {
                    final m = handle.markerData!;
                    return fm.Marker(
                      key: ValueKey('dynamic-${m.id}'),
                      point: handle.point,
                      width: m.width,
                      height: m.height,
                      alignment: m.alignment,
                      child: GestureDetector(
                        onTap: m.onTap,
                        child: m.child,
                      ),
                    );
                  },
                ),
            ..._pendingDynamicMarkers.values.map(
              (m) => fm.Marker(
                key: ValueKey('pending-${m.id}'),
                point: m.point,
                width: m.width,
                height: m.height,
                alignment: m.alignment,
                child: GestureDetector(
                  onTap: m.onTap,
                  child: m.child,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

ml.LatLng _toMl(LatLng point) => ml.LatLng(point.latitude, point.longitude);

class _MarkerHandle {
  _MarkerHandle({
    required this.isDynamic,
    required this.point,
    this.markerData,
  });

  final bool isDynamic;
  LatLng point;
  MapMarkerData? markerData;
  ml.Circle? circle;
  ml.Symbol? symbol;

  bool samePoint(LatLng other) =>
      (point.latitude - other.latitude).abs() <= 1e-9 &&
      (point.longitude - other.longitude).abs() <= 1e-9;

  bool sameMarker(MapMarkerData other) =>
      markerData?.iconImageId == other.iconImageId &&
      markerData?.annotationLabel == other.annotationLabel &&
      markerData?.annotationIsCircle == other.annotationIsCircle;
}

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

bool _labelUsesEmojiGlyphs(String label) {
  for (final code in label.runes) {
    if (code >= 0x1F300) return true;
  }
  return false;
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
