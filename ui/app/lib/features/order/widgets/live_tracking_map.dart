import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:sync_app/features/challenges/widgets/aws_location_map.dart';

class LiveTrackingMap extends StatelessWidget {
  const LiveTrackingMap({
    super.key,
    required this.destination,
    this.shipper,
    this.height = 260,
  });

  final LatLng destination;
  final LatLng? shipper;
  final double height;

  @override
  Widget build(BuildContext context) {
    final markers = <MapMarkerData>[
      MapMarkerData(
        id: 'dest',
        point: destination,
        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        annotationLabel: '📍',
      ),
      if (shipper != null)
        MapMarkerData(
          id: 'shipper',
          point: shipper!,
          child: const Icon(Icons.delivery_dining, color: Color(0xFF2E6B4F), size: 32),
          annotationLabel: '🛵',
        ),
    ];

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AwsLocationMap(
          initialCenter: shipper ?? destination,
          initialZoom: 14,
          markers: markers,
        ),
      ),
    );
  }
}
