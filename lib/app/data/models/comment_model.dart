import 'user_model.dart';

class CommentModel {
  final String id;
  final String userId;
  final String postId;
  final String? parentId; // reply support
  final String commentText;
  final DateTime createdAt;
  final DateTime updatedAt;

  final UserModel? user; // join ke liye (optional)

  CommentModel({
    required this.id,
    required this.userId,
    required this.postId,
    this.parentId,
    required this.commentText,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'],
      userId: json['user_id'],
      postId: json['post_id'],
      parentId: json['parent_id']?.toString(),
      commentText: json['comment_text'] ?? '',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      updatedAt: DateTime.parse(json['updated_at']).toLocal(),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
      'parent_id': parentId,
      'comment_text': commentText
    };
  }
}
