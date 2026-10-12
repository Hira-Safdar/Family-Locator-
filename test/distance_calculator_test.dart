import 'package:flutter_test/flutter_test.dart';
import 'package:familylocator/core/utils/distance_calculator.dart';

void main() {
  group('DistanceCalculator.metersBetween', () {
    test('same point is zero', () {
      expect(DistanceCalculator.metersBetween(30.3753, 69.3451, 30.3753, 69.3451), 0);
    });

    test('one degree of latitude is about 111 km', () {
      final meters = DistanceCalculator.metersBetween(0, 0, 1, 0);
      expect(meters, closeTo(111195, 1000));
    });

    test('London to New York is roughly 5500 km', () {
      final meters = DistanceCalculator.metersBetween(
        51.5074, -0.1278, 40.7128, -74.0060,
      );
      expect(meters / 1000, closeTo(5570, 60));
    });
  });

  group('DistanceCalculator.labelBetween', () {
    test('under 1 km shows rounded meters', () {
      expect(DistanceCalculator.labelBetween(0, 0, 0.001, 0), '111 m');
    });

    test('over 1 km shows one decimal in km', () {
      expect(DistanceCalculator.labelBetween(0, 0, 0.010, 0), '1.1 km');
    });
  });
}