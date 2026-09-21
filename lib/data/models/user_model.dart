class UserProfile{
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json){
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
    };
  }

  UserProfile copyWith({String? name, String? email, String? photoUrl}){
    return UserProfile(
      uid: uid,
      name: name ?? this .name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}