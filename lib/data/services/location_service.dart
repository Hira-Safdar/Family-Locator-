import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/location_point.dart';

class LocationServices {
  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> ensureNotificationPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> ensureBackgroundAccess() async {
    final always = await Permission.locationAlways.status;
    if (!always.isGranted) {
      await Permission.locationAlways.request();
    }
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  Future<LocationPoint> currentPoint() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    return _toPoint(position);
  }

  LocationPoint _toPoint(Position position) => LocationPoint(
    latitude: position.latitude,
    longitude: position.longitude,
    timestamp: DateTime.now(),
    accuracy: position.accuracy,
  );
}
