import 'user_model.dart';

enum StoryMediaType { image, video }

class StoryModel {
  final String id;
  final String userId;
  final List<String> mediaUrls;
  final List<StoryMediaType> mediaTypes;
  final DateTime expiresAt;
  final DateTime createdAt;
  final UserModel? user;
  bool isViewed;

  StoryModel({
    required this.id,
    required this.userId,
    required this.mediaUrls,
    required this.mediaTypes,
    required this.expiresAt,
    required this.createdAt,
    this.user,
    this.isViewed = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'],
      userId: json['user_id'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      mediaTypes: (json['media_types'] as List<dynamic>? ?? [])
          .map((e) => StoryMediaType.values
          .firstWhere((type) => type.name == e))
          .toList(),
      expiresAt: DateTime.parse(json['expires_at']),
      createdAt: DateTime.parse(json['created_at']),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'media_urls': mediaUrls,
      'media_types': mediaTypes.map((e) => e.name).toList(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

