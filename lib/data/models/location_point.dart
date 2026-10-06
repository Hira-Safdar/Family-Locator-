class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final int? batteryLevel;
  final double? accuracy;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.batteryLevel,
    this.accuracy,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) => LocationPoint(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestampMs'] as int),
    batteryLevel: json['batteryLevel'] as int?,
    accuracy: (json['accuracy'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'timestampMs': timestamp.millisecondsSinceEpoch,
    'batteryLevel': batteryLevel,
    'accuracy': accuracy,
  };
}