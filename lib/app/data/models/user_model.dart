class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;
  final String? role;

  final int postsCount;
  final int subscriberCount;
  final int subscribingCount;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
    this.role,
    required this.postsCount,
    required this.subscriberCount,
    required this.subscribingCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      role: json['role'],
      postsCount: json['posts_count'] ?? 0,
      subscriberCount: json['subscriber_count'] ?? 0,
      subscribingCount: json['subscribing_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
      'role': role,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
