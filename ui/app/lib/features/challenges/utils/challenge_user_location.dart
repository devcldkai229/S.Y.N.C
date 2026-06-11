import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/core/config/aws_map_config.dart';
import 'package:sync_app/features/challenges/models/challenge_mock_data.dart';

/// Resolves the user's current coordinates for challenge routing.
abstract final class ChallengeUserLocation {
  static Future<LatLng> resolve() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return fallback;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return fallback;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return fallback;
    }
  }

  static LatLng get fallback => LatLng(
        mockUserLocationLat,
        mockUserLocationLng,
      );

  static LatLng get mapDefault => LatLng(
        AwsMapConfig.defaultLat,
        AwsMapConfig.defaultLng,
      );
}
