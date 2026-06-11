import 'dart:async';

import 'package:geolocator/geolocator.dart';

enum LocationAccess {
  granted,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

/// Resolves device coordinates without blocking app flows when GPS is off.
abstract final class AppLocationResolver {
  static Future<({double? lat, double? lng, LocationAccess access})> resolve({
    bool requestPermission = false,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return (lat: null, lng: null, access: LocationAccess.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return (lat: null, lng: null, access: LocationAccess.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return (lat: null, lng: null, access: LocationAccess.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      ).timeout(timeout);

      return (
        lat: position.latitude,
        lng: position.longitude,
        access: LocationAccess.granted,
      );
    } on TimeoutException {
      return (lat: null, lng: null, access: LocationAccess.unavailable);
    } catch (_) {
      return (lat: null, lng: null, access: LocationAccess.unavailable);
    }
  }
}
