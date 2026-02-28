import 'user_model.dart';

class ShareModel {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;

  final UserModel? user; // optional join support

  ShareModel({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    this.user,
  });

  factory ShareModel.fromJson(Map<String, dynamic> json) {
    return ShareModel(
      id: json['id'],
      userId: json['user_id'],
      postId: json['post_id'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['users'] != null
          ? UserModel.fromJson(json['users'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'post_id': postId,
    };
  }
}
