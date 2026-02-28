
import 'user_model.dart';

enum MediaType { image, video }

class PostModel {
  final String id;
  final String userId;
  final MediaType mediaType;
  final String caption;

  final List<String> mediaUrls;
  final List<String> thumbnailUrls;

  final int likeCount;
  final int commentCount;
  final int shareCount;

  final bool isDeleted;
  final String? location;

  final DateTime createdAt;
  final DateTime updatedAt;
  final UserModel? user;

  PostModel({
    required this.id,
    required this.userId,
    required this.mediaType,
    required this.caption,
    required this.mediaUrls,
    required this.thumbnailUrls,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    required this.isDeleted,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      userId: json['user_id'],
      mediaType: MediaType.values.firstWhere(
            (e) => e.name == (json['media_type'] ?? 'image'),
      ),
      caption: json['caption'] ?? '',
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      thumbnailUrls: List<String>.from(json['thumbnail_urls'] ?? []),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      shareCount: json['share_count'] ?? 0,
      isDeleted: json['is_deleted'] ?? false,
      location: json['location'],
      // createdAt: DateTime.parse(json['created_at']),
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,                // ✅ join data
    );
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'user_id': userId,
      'media_type': mediaType.name,
      'caption': caption,
      'media_urls': mediaUrls,
      'thumbnail_urls': thumbnailUrls,
      'location': location,
    };
  }
}
