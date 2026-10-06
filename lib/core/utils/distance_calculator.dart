import 'package:geolocator/geolocator.dart';

class DistanceCalculator {
  static double metersBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  static String labelBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final meters = metersBetween(lat1, lng1, lat2, lng2);
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
