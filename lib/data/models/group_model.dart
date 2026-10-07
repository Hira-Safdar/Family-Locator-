import '../../core/constants/group_categories.dart';

class GroupModel {
  final String id;
  final String name;
  final String category;
  final String inviteCode;
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  const GroupModel({
    required this.id,
    required this.name,
    required this.category,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['memberIds'];
    final rawCreatedAt = json['createdAt'];

    return GroupModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: GroupCategories.normalize(json['category'] as String?),
      inviteCode: json['inviteCode'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      memberIds: rawMembers is List
          ? rawMembers.map((item) => item.toString()).toList()
          : const <String>[],
      createdAt: rawCreatedAt is String
          ? DateTime.tryParse(rawCreatedAt) ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool containsMember(String uid) {
    return memberIds.contains(uid);
  }

  GroupModel copyWith({
    String? name,
    String? category,
    String? inviteCode,
    List<String>? memberIds,
  }) {
    return GroupModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      ownerId: ownerId,
      createdAt: createdAt,
    );
  }
}
