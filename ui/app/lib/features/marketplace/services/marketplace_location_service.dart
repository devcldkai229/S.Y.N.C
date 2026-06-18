import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/config/aws_map_config.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/models/marketplace_home_models.dart';
import 'package:sync_app/features/order/data/checkout_remote_data_source.dart';

abstract final class MarketplaceLocationService {
  static final Map<String, String> _reverseCache = {};

  static LatLng snapForGeocode(double lat, double lng) {
    // ~11 m grid — giảm lệch địa chỉ do GPS jitter.
    return LatLng(
      (lat * 10000).round() / 10000,
      (lng * 10000).round() / 10000,
    );
  }

  static String _cacheKey(double lat, double lng) {
    final snapped = snapForGeocode(lat, lng);
    return '${snapped.latitude},${snapped.longitude}';
  }

  static Future<String?> reverseGeocode(double lat, double lng) async {
    final key = _cacheKey(lat, lng);
    final cached = _reverseCache[key];
    if (cached != null) return cached;

    try {
      final snapped = snapForGeocode(lat, lng);
      final result = await getIt<CheckoutRemoteDataSource>().reverseGeocode(
        snapped.latitude,
        snapped.longitude,
      );
      final label = _stableLabel(result) ?? result.label.trim();
      if (label.isEmpty || _looksLikeCoordinateLabel(label)) return null;
      _reverseCache[key] = label;
      return label;
    } catch (_) {
      return null;
    }
  }

  static String? _stableLabel(ReverseGeocodeResult result) {
    final parts = <String>[];
    final line = result.addressLine?.trim();
    if (line != null && line.isNotEmpty) {
      parts.add(line);
    }
    for (final part in [result.ward, result.district, result.city]) {
      final value = part?.trim();
      if (value != null && value.isNotEmpty && !parts.contains(value)) {
        parts.add(value);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  static bool _looksLikeCoordinateLabel(String label) {
    final normalized = label.replaceAll(' ', '');
    return RegExp(r'^-?\d+(\.\d+)?,-?\d+(\.\d+)?$').hasMatch(normalized);
  }

  static Future<void> saveDeliveryAddress({
    required String label,
    required double lat,
    required double lng,
  }) async {
    await getIt<CheckoutRemoteDataSource>().saveCurrentAddress(
      label: label,
      lat: lat,
      lng: lng,
    );
  }

  static DeliveryLocation fromCoordinates(double lat, double lng, String fullAddress) =>
      DeliveryLocation(
        lat: lat,
        lng: lng,
        shortLabel: shortenAddress(fullAddress),
        fullAddress: fullAddress,
      );

  /// Bold line (street) + optional remainder — never repeats the same segment.
  static ({String headline, String? subtitle}) splitAddressDisplay(String full) {
    final parts = full
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (headline: full, subtitle: null);
    if (parts.length == 1) return (headline: parts[0], subtitle: null);

    final headline = parts[0];
    final rest = parts.sublist(1).join(', ');
    if (rest.isEmpty || rest.toLowerCase() == headline.toLowerCase()) {
      return (headline: headline, subtitle: null);
    }
    return (headline: headline, subtitle: rest);
  }

  static String shortenAddress(String full) => splitAddressDisplay(full).headline;

  static double get defaultLat => AwsMapConfig.defaultLat;
  static double get defaultLng => AwsMapConfig.defaultLng;
}
