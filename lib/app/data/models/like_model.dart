import 'user_model.dart';

class LikeModel {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;
  final UserModel? user;

  LikeModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
    this.user,
  });

  factory LikeModel.fromJson(Map<String, dynamic> json) {
    return LikeModel(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'post_id': postId,
      'user_id': userId,
    };
  }
}
