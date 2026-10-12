class SosAlert{
  final String uid;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;

  const SosAlert({
    required this.uid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble()?? 0,
      longitude: (json['longitude'] as num?)?.toDouble()?? 0,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String)??
          DateTime.fromMillisecondsSinceEpoch(0)
       :DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String,dynamic> toJson(){
    return{
      'uid' : uid,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt' : createdAt.toIso8601String(),
    };
  }
}