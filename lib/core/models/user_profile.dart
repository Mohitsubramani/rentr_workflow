class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.photoUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      uid: data['uid'],
      name: data['name'],
      email: data['email'],
      role: data['role'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'photoUrl': photoUrl,
      'createdAt': DateTime.now(),
    };
  }
}
