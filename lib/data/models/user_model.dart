class UserProfile{
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? phone;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json){
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      phone: json['phone'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'phone': phone,
    };
  }

  UserProfile copyWith({String? name, String? email, String? photoUrl, String? phone}){
    return UserProfile(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
    );
  }
}
