class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? city;
  final String? university;
  final String? myo;
  final String? bio;

  Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    this.city,
    this.university,
    this.myo,
    this.bio,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      city: json['city'] as String?,
      university: json['university'] as String?,
      myo: json['myo'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'city': city,
      'university': university,
      'myo': myo,
      'bio': bio,
    };
  }
}
