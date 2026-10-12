class AlertRecord {
  final String id;
  final String groupId;
  final String uid;
  final String name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const AlertRecord({
    required this.id,
    required this.groupId,
    required this.uid,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.resolvedAt,
  });

  factory AlertRecord.fromJson(String id, Map<String, dynamic> json) {
    return AlertRecord(
      id: id,
      groupId: json['groupId'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] is String
          ? DateTime.tryParse(json['createdAt'] as String) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      resolvedAt: json['resolvedAt'] is String
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'uid': uid,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }
}