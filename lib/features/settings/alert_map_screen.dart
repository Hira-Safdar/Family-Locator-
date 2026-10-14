import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AlertMapScreen extends StatelessWidget {
  const AlertMapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.name,
  });

  final double latitude;
  final double longitude;
  final String name;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(latitude, longitude);
    return Scaffold(
      appBar: AppBar(
        title: Text(name.isEmpty ? 'Alert location' : name),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: target, zoom: 16),
        markers: {
          Marker(
            markerId: const MarkerId('alert'),
            position: target,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
        mapToolbarEnabled: false,
      ),
    );
  }
}
