class GroupModel {                                        // 'Model' = data ka khaka (Firestore se aane wala group)
  final String id;                                        // group ka unique number (Firestore doc id) — yeh kabhi nahi badalta
  final String name;                                      // group ka naam, jaise "Ghar ki Family"
  final String inviteCode;                                // 6-char wala code jo dost ko batana hai
  final String ownerId;                                   // jis user ne group banaya (uska uid) — sirf yehi owner bolega
  final List<String> memberIds;                           // un sab users ke uid ki list jinhone group join kiya
  final DateTime createdAt;                               // group kab bana (time) — listing ke liye zaroori

  const GroupModel({                                      // const constructor = yeh data kabhi badlega nahi
    required this.id,                                     // har field zaroori diya jaye (nahi to compile error)
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {  // Firestore ka raw map -> GroupModel banata hai
    return GroupModel(                                      // map se values nikaal ke constructor ko deta hai
      id: json['id'] as String,                             // 'as String' = batao ke yeh value String hi hai
      name: json['name'] as String,
      inviteCode: json['inviteCode'] as String,
      ownerId: json['ownerId'] as String,
      memberIds: (json['memberIds'] as List).cast<String>(), // List<String> bana rahe hain (as List wali list se)
      createdAt: DateTime.parse(json['createdAt'] as String),// Firestore date ko String se real clock-time mein badalte hain
    );
  }

  Map<String, dynamic> toJson() {                           // GroupModel -> Firestore ko dene wala map
    return {
      'id': id,                                             // har field map mein same naam ke saath
      'name': name,
      'inviteCode': inviteCode,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': createdAt.toIso8601String(),             // DateTime ko ISO string mein (takay Firestore seh sake)
    };
  }

  bool containsMember(String uid) {                         // check: yeh user is group ka member hai ya nahi
    return memberIds.contains(uid);                         // list mein uid mili to true, warna false
  }

  GroupModel copyWith({                                    // purana group e, sirf kuch fields change karke naya group
    String? name,
    String? inviteCode,                                     // '?' ka matlab: yeh value dena zaroori nahi
    List<String>? memberIds,
  }) {
    return GroupModel(                                      // naya object banta hai
      id: id,                                               // id wahi purani (id kabhi nahi badalti)
      name: name ?? this.name,                              // '??' = agar nayi name di gayi to woh, warna purani rakho
      inviteCode: inviteCode ?? this.inviteCode,
      memberIds: memberIds ?? this.memberIds,
      ownerId: ownerId,
      createdAt: createdAt,
    );
  }
}