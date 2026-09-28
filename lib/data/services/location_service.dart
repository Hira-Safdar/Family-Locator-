import 'dart:async';

import 'package:geolocator/geolocator.dart';
import '../../core/utils/distance_calculator.dart';
import '../models/location_point.dart';

typedef LocationListener = void Function(LocationPoint  point);

class LocationServices{
  LocationServices({this.minMeters = 50});

  final double minMeters;
  Timer? _timer;
  LocationPoint? _last;


  Future<bool> ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

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

  void startTracking(LocationListener onUpdate) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final point = await currentPoint();
        if (!_movedEnough(point)) return;
        _last = point;
        onUpdate(point);
      } catch (_) {}
    });
  }

  void stopTracking(){
    _timer?.cancel();
    _timer = null;
  }

  bool _movedEnough(LocationPoint point) {
    final last = _last;
    if(last == null) return true;
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
