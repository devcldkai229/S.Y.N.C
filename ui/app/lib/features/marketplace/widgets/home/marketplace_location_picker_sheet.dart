import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/app/router/app_router.dart';
import 'package:sync_app/core/config/aws_map_config.dart';
import 'package:sync_app/core/utils/app_location_resolver.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/marketplace/services/marketplace_location_service.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

/// Full-screen AWS map picker for delivery address (Grab/MapLibre + Place Index search).
class MarketplaceLocationPickerScreen extends StatefulWidget {
  const MarketplaceLocationPickerScreen({super.key, this.initial});

  final DeliveryLocation? initial;

  static Future<DeliveryLocation?> show(BuildContext context, {DeliveryLocation? initial}) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null) return Future.value();

    return navigator.push<DeliveryLocation>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => MarketplaceLocationPickerScreen(initial: initial),
      ),
    );
  }

  @override
  State<MarketplaceLocationPickerScreen> createState() => _MarketplaceLocationPickerScreenState();
}

class _MarketplaceLocationPickerScreenState extends State<MarketplaceLocationPickerScreen> {
  final _mapKey = GlobalKey<AwsLocationMapState>();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _checkout = getIt<CheckoutRemoteDataSource>();

  late LatLng _center;
  final _addressUi = ValueNotifier(const _AddressUi.loading());
  bool _locating = false;
  bool _searching = false;
  List<AddressSuggestion> _suggestions = const [];
  Timer? _searchDebounce;
  LatLng? _lastGeocodedPoint;
  int _geocodeSeq = 0;
  bool _initialGpsRequested = false;
  bool _skipNextMapIdle = true;
  LatLng? _pendingMapCenter;

  static const _geocodeMinMoveMeters = 45.0;
  static const _distance = Distance();

  @override
  void initState() {
    super.initState();
    _center = LatLng(
      widget.initial?.lat ?? AwsMapConfig.defaultLat,
      widget.initial?.lng ?? AwsMapConfig.defaultLng,
    );
    _searchController.addListener(_onSearchChanged);
    final initial = widget.initial;
    if (initial != null && initial.fullAddress.isNotEmpty) {
      _addressUi.value = _AddressUi.ready(initial.fullAddress);
      _lastGeocodedPoint = _center;
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _addressUi.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final q = _searchController.text.trim();
      if (q.length < 2) {
        if (mounted) setState(() => _suggestions = const []);
        return;
      }
      setState(() => _searching = true);
      try {
        final results = await _checkout.searchAddress(
          q,
          lat: _center.latitude,
          lng: _center.longitude,
        );
        if (!mounted) return;
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  bool _isValidGeoPoint(LatLng point) {
    return point.latitude.abs() > 0.0001 &&
        point.longitude.abs() > 0.0001 &&
        point.latitude.abs() <= 90 &&
        point.longitude.abs() <= 180;
  }

  /// AWS returns [lng, lat]; backend maps correctly — swap only if values look inverted.
  LatLng _coordsFromApi(double lat, double lng) {
    final direct = LatLng(lat, lng);
    if (_isValidGeoPoint(direct)) return direct;
    final swapped = LatLng(lng, lat);
    if (_isValidGeoPoint(swapped)) return swapped;
    return direct;
  }

  LatLng _snapPoint(LatLng point) {
    final snapped = MarketplaceLocationService.snapForGeocode(point.latitude, point.longitude);
    return LatLng(snapped.latitude, snapped.longitude);
  }

  Future<void> _resolveAddress(LatLng point, {bool force = false}) async {
    if (!_isValidGeoPoint(point)) return;

    final snapped = _snapPoint(point);
    if (!force &&
        _lastGeocodedPoint != null &&
        _distance.as(LengthUnit.Meter, _lastGeocodedPoint!, snapped) < _geocodeMinMoveMeters) {
      _center = point;
      return;
    }

    final seq = ++_geocodeSeq;
    final hadAddress = _addressUi.value.fullAddress != null;
    if (!hadAddress) {
      _addressUi.value = const _AddressUi.loading();
    }

    final full = await MarketplaceLocationService.reverseGeocode(snapped.latitude, snapped.longitude);
    if (!mounted || seq != _geocodeSeq) return;

    if (full == null) {
      if (!hadAddress) {
        _addressUi.value = const _AddressUi.error(
          'Không lấy được địa chỉ. Hãy tìm địa chỉ hoặc thử lại GPS.',
        );
      }
      return;
    }

    _addressUi.value = _AddressUi.ready(full);
    _lastGeocodedPoint = snapped;
    _center = point;
    if (_suggestions.isNotEmpty) {
      setState(() => _suggestions = const []);
    }
  }

  Future<void> _applySelectedLocation(LatLng point, String label, {bool fromSearch = false}) async {
    final snapped = _snapPoint(point);
    _skipNextMapIdle = true;
    _center = snapped;
    _searchFocus.unfocus();
    setState(() => _suggestions = const []);
    await _moveMapTo(snapped, zoom: 16);
    _lastGeocodedPoint = snapped;
    _addressUi.value = _AddressUi.ready(label.trim());
    if (fromSearch) {
      _searchController.text = label;
    }
  }

  void _selectSuggestion(AddressSuggestion s) {
    if (s.lat == 0 && s.lng == 0) {
      _searchController.text = s.label;
      return;
    }
    unawaited(_applySelectedLocation(_coordsFromApi(s.lat, s.lng), s.label, fromSearch: true));
  }

  Future<void> _onMapReady() async {
    final pending = _pendingMapCenter;
    if (pending != null) {
      _pendingMapCenter = null;
      await _moveMapTo(pending, zoom: 16);
    } else if (widget.initial == null && !_initialGpsRequested) {
      _initialGpsRequested = true;
      unawaited(_goToCurrentLocation(silent: true));
    } else if (widget.initial != null && widget.initial!.fullAddress.isEmpty) {
      unawaited(_resolveAddress(_center, force: true));
    }
  }

  void _onMapCenterIdle(LatLng center) {
    if (!_isValidGeoPoint(center)) return;
    if (_skipNextMapIdle) {
      _skipNextMapIdle = false;
      _center = center;
      return;
    }
    _center = center;
    unawaited(_resolveAddress(center));
  }

  Future<void> _moveMapTo(LatLng point, {double zoom = 16}) async {
    final map = _mapKey.currentState;
    if (map == null) {
      _pendingMapCenter = point;
      return;
    }
    await map.moveTo(point, zoom: zoom);
  }

  Future<void> _goToCurrentLocation({bool silent = false}) async {
    if (_locating) return;

    setState(() => _locating = true);

    final map = _mapKey.currentState;
    if (map != null) {
      final result = await map.centerOnUserLocation(zoom: 16);
      if (!mounted) return;
      setState(() => _locating = false);

      if (result != UserLocationCenterResult.success) {
        if (silent) return;
        switch (result) {
          case UserLocationCenterResult.gpsDisabled:
            await Geolocator.openLocationSettings();
          case UserLocationCenterResult.permissionDeniedForever:
            await Geolocator.openAppSettings();
          case UserLocationCenterResult.permissionDenied:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cần quyền vị trí để định vị GPS')),
            );
          case UserLocationCenterResult.unavailable:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không lấy được vị trí — hãy tìm địa chỉ')),
            );
          case UserLocationCenterResult.success:
            break;
        }
        return;
      }

      final center = map.lastCenteredLocation ?? map.mapCenter;
      if (center != null) {
        _skipNextMapIdle = true;
        _center = center;
        await _resolveAddress(center, force: true);
      }
      return;
    }

    final result = await AppLocationResolver.resolve(requestPermission: true);
    if (!mounted) return;
    setState(() => _locating = false);

    if (result.lat == null || result.lng == null) {
      if (silent) return;
      switch (result.access) {
        case LocationAccess.serviceDisabled:
          await Geolocator.openLocationSettings();
        case LocationAccess.permissionDeniedForever:
          await Geolocator.openAppSettings();
        case LocationAccess.permissionDenied:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cần quyền vị trí để định vị GPS')),
          );
        case LocationAccess.granted:
        case LocationAccess.unavailable:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không lấy được vị trí — hãy tìm địa chỉ')),
          );
      }
      return;
    }

    final point = LatLng(result.lat!, result.lng!);
    _skipNextMapIdle = true;
    _center = point;
    await _moveMapTo(point, zoom: 16);
    await _resolveAddress(point, force: true);
  }

  Future<void> _confirm() async {
    final center = _snapPoint(_center);
    final address = _addressUi.value.fullAddress;
    if (address == null) return;

    try {
      await MarketplaceLocationService.saveDeliveryAddress(
        label: address,
        lat: center.latitude,
        lng: center.longitude,
      );
    } catch (_) {}

    if (!mounted) return;
    Navigator.pop(
      context,
      MarketplaceLocationService.fromCoordinates(center.latitude, center.longitude, address),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usesAwsMap = AwsMapConfig.usesVectorMap;

    return Scaffold(
      backgroundColor: MarketplaceTheme.background,
      appBar: AppBar(
        backgroundColor: MarketplaceTheme.background,
        elevation: 0,
        foregroundColor: MarketplaceTheme.heading,
        title: const Text('Giao đến', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Tìm địa chỉ, quận, đường…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _suggestions = const []);
                            },
                          )
                        : null),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!usesAwsMap)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Chạy app với AWS map key (scripts/run-chrome.ps1) để dùng bản đồ Grab/AWS.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade800),
              ),
            ),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: MarketplaceTheme.cardShadow(),
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _suggestions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = _suggestions[i];
                  return ListTile(
                    leading: const Icon(Icons.place_outlined, color: MarketplaceTheme.primary),
                    dense: true,
                    title: Text(s.label, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectSuggestion(s),
                  );
                },
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                _PickerMapView(
                  mapKey: _mapKey,
                  initialCenter: _center,
                  onMapReady: _onMapReady,
                  onCenterChanged: _onMapCenterIdle,
                ),
                const IgnorePointer(
                  child: Center(
                    child: _MapCenterPin(),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'marketplace-locate-picker',
                    backgroundColor: Colors.white,
                    onPressed: _locating ? null : () => _goToCurrentLocation(),
                    child: _locating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location_rounded, color: MarketplaceTheme.primary),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<_AddressUi>(
            valueListenable: _addressUi,
            builder: (context, addressUi, _) {
              final display = addressUi.fullAddress != null
                  ? MarketplaceLocationService.splitAddressDisplay(addressUi.fullAddress!)
                  : null;
              return Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.paddingOf(context).bottom + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: MarketplaceTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            addressUi.loading
                                ? 'Đang tải địa chỉ…'
                                : addressUi.errorMessage ?? display?.headline ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: addressUi.errorMessage != null ? Colors.orange.shade800 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!addressUi.loading && display?.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 28, top: 4),
                        child: Text(
                          display!.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: MarketplaceTheme.textMuted),
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 28),
                      child: Text(
                        'Kéo bản đồ hoặc tìm địa chỉ — ghim giữa màn là vị trí giao hàng',
                        style: TextStyle(fontSize: 11, color: MarketplaceTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: addressUi.canConfirm ? _confirm : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: MarketplaceTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Xác nhận địa chỉ'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AddressUi {
  const _AddressUi._({
    required this.loading,
    this.fullAddress,
    this.errorMessage,
  });

  const _AddressUi.loading() : this._(loading: true);

  const _AddressUi.error(String message)
      : this._(loading: false, errorMessage: message);

  factory _AddressUi.ready(String address) => _AddressUi._(loading: false, fullAddress: address);

  final bool loading;
  final String? fullAddress;
  final String? errorMessage;

  bool get canConfirm => !loading && fullAddress != null && fullAddress!.isNotEmpty;
}

/// Map layer isolated from address-bar updates to avoid MapLibre rebuild jank.
class _PickerMapView extends StatefulWidget {
  const _PickerMapView({
    required this.mapKey,
    required this.initialCenter,
    required this.onMapReady,
    required this.onCenterChanged,
  });

  final GlobalKey<AwsLocationMapState> mapKey;
  final LatLng initialCenter;
  final VoidCallback onMapReady;
  final void Function(LatLng center) onCenterChanged;

  @override
  State<_PickerMapView> createState() => _PickerMapViewState();
}

class _PickerMapViewState extends State<_PickerMapView> {
  @override
  Widget build(BuildContext context) {
    return AwsLocationMap(
      key: widget.mapKey,
      initialCenter: widget.initialCenter,
      initialZoom: 15,
      showUserLocation: true,
      interactive: true,
      pickerMode: true,
      onReady: widget.onMapReady,
      onPickerCenterChanged: widget.onCenterChanged,
    );
  }
}

class _MapCenterPin extends StatelessWidget {
  const _MapCenterPin();

  static const _iconSize = 46.0;

  @override
  Widget build(BuildContext context) {
    // Tip of location_on sits at the bottom — shift up so tip = map viewport center.
    return Transform.translate(
      offset: const Offset(0, -_iconSize / 2),
      child: Icon(
        Icons.location_on_rounded,
        size: _iconSize,
        color: MarketplaceTheme.primary,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
