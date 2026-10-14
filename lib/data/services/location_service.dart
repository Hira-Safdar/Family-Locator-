import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/distance_calculator.dart';
import '../models/location_point.dart';

typedef LocationListener = void Function(LocationPoint point);

class LocationServices {
  LocationServices({this.minMeters = 50});

  final double minMeters;
  StreamSubscription<Position>? _subscription;
  LocationPoint? _last;

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

  Future<void> startTracking(
    LocationListener onUpdate, {
    int seconds = 10,
  }) async {
    await _subscription?.cancel();
    _subscription = null;
    _subscription =
        Geolocator.getPositionStream(
          locationSettings: _settings(seconds),
        ).listen((position) {
          final point = _toPoint(position);
          if (!_movedEnough(point)) return;
          _last = point;
          onUpdate(point);
        }, onError: (_) {});
  }

  Future<void> stopTracking() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  LocationSettings _settings(int seconds) {
    const notification = ForegroundNotificationConfig(
      notificationTitle: 'Family Locator is sharing your location',
      notificationText: 'Your family can see you on the map.',
      notificationChannelName: 'Location sharing',
      enableWakeLock: true,
      setOngoing: true,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: minMeters.round(),
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
      );
    }

    return AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: minMeters.round(),
      intervalDuration: Duration(seconds: seconds),
      foregroundNotificationConfig: notification,
    );
  }

  bool _movedEnough(LocationPoint point) {
    final last = _last;
    if (last == null) return true;
    final meters = DistanceCalculator.metersBetween(
      last.latitude,
      last.longitude,
      point.latitude,
      point.longitude,
    );
    return meters >= minMeters;
  }

  LocationPoint _toPoint(Position position) => LocationPoint(
    latitude: position.latitude,
    longitude: position.longitude,
    timestamp: DateTime.now(),
    accuracy: position.accuracy,
  );
}
