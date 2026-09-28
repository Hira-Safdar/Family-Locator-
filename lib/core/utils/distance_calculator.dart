import 'package:geolocator/geolocator.dart';

class DistanceCalculator{
  static double metersBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,

  ) =>
      Geolocator.distanceBetween(lat1,lng1,lat2,lng2);
}